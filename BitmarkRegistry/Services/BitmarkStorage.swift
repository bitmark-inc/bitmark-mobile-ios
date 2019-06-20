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

  lazy var directoryURL: URL = {
    let directoryURL = URL(
      fileURLWithPath: owner.getAccountNumber(),
      relativeTo: FileManager.documentDirectoryURL
    )
    try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    print(directoryURL)
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

  func firstLoad(handler: @escaping ([Bitmark]?, Error?) -> Void) throws {
    Global.latestBitmarkOffset = try getStoredPathName()
    if Global.latestBitmarkOffset == nil {
      DispatchQueue.global(qos: .background).async { [weak self] in
        guard let self = self else { return }
        do {
          try self.sync()
          let bitmarks = try self.getBitmarkData()
          DispatchQueue.main.async {
            handler(bitmarks, nil)
          }
        } catch let e {
          DispatchQueue.main.async { handler(nil, e) }
        }
      }
    } else {
      let bitmarks = try getBitmarkData()
      handler(bitmarks, nil)
      DispatchQueue.global(qos: .background).async { [weak self] in
        do {
          try self?.sync(notifyNew: true)
        } catch let e {
          DispatchQueue.main.async { handler(nil, e) }
        }
      }
    }
  }

  func sync(notifyNew: Bool = false) throws {
    Global.latestBitmarkOffset = try getStoredPathName()
    var latestOffset = Global.latestBitmarkOffset ?? 0

    repeat {
      let (bitmarks, assets) = try BitmarkService.listAllBitmarksWithAsset(owner: owner, at: latestOffset, direction: .later)

      if notifyNew {
        for newBitmark in bitmarks {
          let duplicatedIndex = delegate?.bitmarks.firstIndex(where: { $0.id == newBitmark.id })

          DispatchQueue.main.async { [weak self] in
            self?.delegate?.receiveNewBitmark(newBitmark, duplicatedRow: duplicatedIndex)
          }
        }
      }

      let bitmarksWithAsset = BitmarksWithAsset(assets: assets, bitmarks: bitmarks)

      guard bitmarks.count > 0 else { break }

      let baseOffset = bitmarks.sorted(by: { $0.offset > $1.offset }).first!.offset
      let bitmarksURL = fileURL(pathName: baseOffset)

      if latestOffset == 0 {
        try bitmarksWithAsset.store(in: bitmarksURL)
      } else {
        try mergeNewBitmarks(bitmarksURL, bitmarksWithAsset)
      }

      latestOffset = baseOffset
      Global.latestBitmarkOffset = latestOffset
    } while true
  }

  // Merge new bitmarks into the bitmarks file
  fileprivate func mergeNewBitmarks(_ newBitmarksURL: URL, _ bitmarksWithAsset: BitmarksWithAsset) throws {
    guard let latestPathName = Global.latestBitmarkOffset else { return }
    let latestBitmarksURL = fileURL(pathName: latestPathName)
    var oldBitmarksWithAsset = try BitmarksWithAsset(from: latestBitmarksURL)
    try oldBitmarksWithAsset.merge(with: bitmarksWithAsset, in: latestBitmarksURL, newBitmarksURL: newBitmarksURL)
  }

  // MARK: - Support Functions
  fileprivate func getSize(for url: URL) throws -> UInt64? {
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    return attributes[.size] as? UInt64 ?? nil
  }

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
