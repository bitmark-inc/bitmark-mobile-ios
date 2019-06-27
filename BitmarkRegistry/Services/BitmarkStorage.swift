//
//  BitmarkStorage.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/16/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class BitmarkStorage {
  var owner: Account
  var delegate: BitmarkEventDelegate?
  let pathExtension = "json"
  private let serialSyncBitmarkQueue = DispatchQueue(label: "com.bitmark.registry.syncBitmarkQueue")

  // Get/create directory in documentURL; which directory's name is current account number
  lazy var directoryURL: URL = {
    let directoryURL = URL(
      fileURLWithPath: owner.getAccountNumber(),
      relativeTo: FileManager.documentDirectoryURL
    )
    try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    return directoryURL
  }()

  init(for owner: Account) {
    self.owner = owner
  }

  func getBitmarkData() throws -> [Bitmark] {
    if let bitmarksURL = try getBitmarksURL() {
      let bitmarksWithAsset = try BitmarksWithAsset(from: bitmarksURL)
      Global.addAssets(bitmarksWithAsset.assets)
      return bitmarksWithAsset.bitmarks.reversed()
    }
    return [Bitmark]()
  }

  /**
   - If data no exist in local storage:
      * execute sync all bitmarks from beginning (without notifyNew cause we already wait for sync all and display data)
      * get and returns data to display in UI
   - If data exists in local storage:
      * load existing data into UI
      * execute sync in background and update bitmark rows if any change
   */
  func firstLoad(handler: @escaping ([Bitmark]?, Error?) -> Void) throws {
    Global.latestBitmarkOffset = try getStoredPathName()
    if Global.latestBitmarkOffset == nil {
      asyncSerialMoreBitmarks(notifyNew: false) { (executeSyncResult) in
        do {
          try executeSyncResult()
          let bitmarks = try self.getBitmarkData()
          DispatchQueue.main.async { handler(bitmarks, nil) }
        } catch let e {
          DispatchQueue.main.async { handler(nil, e) }
        }
      }
    } else {
      let bitmarks = try getBitmarkData()
      handler(bitmarks, nil)
      asyncSerialMoreBitmarks(notifyNew: true, completion: nil)
    }
  }

  // Call Async function in serial queue
  typealias throwsFunction = () throws -> Void
  func asyncSerialMoreBitmarks(notifyNew: Bool, callAPIOneTime: Bool = false, completion: ((_ inner: throwsFunction) -> Void)?) {
    serialSyncBitmarkQueue.async { [weak self] in
      do {
        try self?.syncBitmark(notifyNew: notifyNew, callAPIOneTime: callAPIOneTime)
        completion?({})
      } catch let e {
        print(e.localizedDescription)
        completion?({ throw e })
      }
    }
  }

  /**
   Sync and merge all bitmarks into a file; set the latest offset as the filename
   - Parameters:
      - notifyNew: when true, notify receiveNewBitmarks to update in UI
      - callAPIOneTime: to make one call listBitmarks API one only
          when we're sure that there are no remain bitmarks in next API,
          such as: in eventSubscription
   */
  fileprivate func syncBitmark(notifyNew: Bool, callAPIOneTime: Bool = false) throws {
    Global.latestBitmarkOffset = try getStoredPathName()
    var latestOffset = Global.latestBitmarkOffset ?? 0

    repeat {
      let (bitmarks, assets) = try BitmarkService.listAllBitmarksWithAsset(owner: owner, at: latestOffset, direction: .later)
      guard bitmarks.count > 0 else { break }

      var bitmarksWithAsset = BitmarksWithAsset(assets: assets, bitmarks: bitmarks)

      if notifyNew {
        Global.addAssets(bitmarksWithAsset.assets)
        DispatchQueue.main.async { [weak self] in
          self?.delegate?.receiveNewBitmarks(bitmarks)
        }
      }

      let baseOffset = bitmarks.last!.offset // the last offset is the latest offset cause response bitmarks is asc-offset
      let bitmarksURL = fileURL(pathName: baseOffset)

      if latestOffset == 0 {
        try bitmarksWithAsset.store(in: bitmarksURL, ownerNumber: owner.getAccountNumber())
      } else {
        try mergeNewBitmarks(bitmarksURL, bitmarksWithAsset)
      }

      latestOffset = baseOffset
      Global.latestBitmarkOffset = latestOffset
    } while !callAPIOneTime
  }

  // Merge new bitmarks into the bitmarks file
  fileprivate func mergeNewBitmarks(_ newBitmarksURL: URL, _ bitmarksWithAsset: BitmarksWithAsset) throws {
    guard let latestPathName = Global.latestBitmarkOffset else { return }
    let latestBitmarksURL = fileURL(pathName: latestPathName)
    var oldBitmarksWithAsset = try BitmarksWithAsset(from: latestBitmarksURL)
    try oldBitmarksWithAsset.merge(
      with: bitmarksWithAsset,
      ownerNumber: owner.getAccountNumber(),
      from: latestBitmarksURL,
      to: newBitmarksURL
    )
  }

  // MARK: - Support Functions
  fileprivate func fileURL(pathName: Int64) -> URL {
    return directoryURL.appendingPathComponent(String(pathName)).appendingPathExtension(pathExtension)
  }

  fileprivate func getBitmarksURL() throws -> URL? {
    if let latestPathName = Global.latestBitmarkOffset {
      return fileURL(pathName: latestPathName)
    }
    return nil
  }

  fileprivate func getStoredPathName() throws -> Int64? {
    let directoryContents = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
    let offsets = directoryContents.compactMap { (fileURL) -> Int64? in
      let fileURL = fileURL.deletingPathExtension()
      return Int64(fileURL.lastPathComponent) ?? nil
    }
    return offsets.first
  }
}
