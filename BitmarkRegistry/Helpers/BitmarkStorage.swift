//
//  BitmarkStorage.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/5/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class BitmarkStorage {
  var owner: Account
  let pathExtension = "json"
  let minimumSize = 50_000 // about 50 KB

  lazy var directoryURL: URL = {
    let directoryURL = URL(fileURLWithPath: owner.getAccountNumber(), relativeTo: FileManager.documentDirectoryURL)
    try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    print(directoryURL)
    return directoryURL
  }()

  init(for owner: Account) {
    self.owner = owner
  }

  func getBitmarkData(fromOffset: Int64? = nil) throws -> [Bitmark] {
    if let bitmarksURL = try getLatestBitmarksURL() {
      let bitmarksWithAsset = try BitmarksWithAsset(from: bitmarksURL)
      Global.addAssets(bitmarksWithAsset.assets)
      return bitmarksWithAsset.bitmarks
    }
    return [Bitmark]()
  }

  func sync() throws {
    Global.storedBitmarksPathNames = try getStoredPathNames()
    let latestPathName = Global.storedBitmarksPathNames.first
    var latestOffset = latestPathName != nil ? Int64(latestPathName!)! : 0
    var willConnectBitmarksInLatestFile = latestOffset != 0

    repeat {
      let (bitmarks, assets) = try BitmarkService.listAllBitmarksWithAsset(owner: owner, at: latestOffset, direction: .later)
      let bitmarksWithAsset = BitmarksWithAsset(assets: assets, bitmarks: bitmarks)

      guard bitmarks.count > 0 else { break }

      let baseOffset = bitmarks.sorted(by: { $0.offset > $1.offset }).first!.offset
      let bitmarksURL = fileURL(pathName: String(baseOffset))

      if willConnectBitmarksInLatestFile {
        try connectIncomingBitmarks(bitmarksURL, bitmarksWithAsset)
        willConnectBitmarksInLatestFile = false
      } else {
        try bitmarksWithAsset.store(in: bitmarksURL)
      }

      latestOffset = baseOffset
      Global.storedBitmarksPathNames.insert(String(latestOffset), at: 0)
    } while true
  }


  /*
   */
  func connectIncomingBitmarks(_ newBitmarksURL: URL, _ bitmarksWithAsset: BitmarksWithAsset) throws {
    let latestPathName = Global.storedBitmarksPathNames.first!
    let latestBitmarksURL = fileURL(pathName: latestPathName)
    if let fileSize = try getSize(for: latestBitmarksURL), fileSize < minimumSize {
      var oldBitmarksWithAsset = try BitmarksWithAsset(from: latestBitmarksURL)
      oldBitmarksWithAsset.merge(with: bitmarksWithAsset)
      try oldBitmarksWithAsset.reStore(in: latestBitmarksURL, newBitmarksURL: newBitmarksURL)
    } else {
      try bitmarksWithAsset.store(in: newBitmarksURL)
    }
  }

  func getSize(for url: URL) throws -> UInt64? {
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    return attributes[.size] as? UInt64 ?? nil
  }

  private func fileURL(pathName: String) -> URL {
    return directoryURL.appendingPathComponent(pathName).appendingPathExtension(pathExtension)
  }

  private func getLatestBitmarksURL() throws -> URL? {
    Global.storedBitmarksPathNames = try getStoredPathNames()
    if let latestPathName = Global.storedBitmarksPathNames.first {
      return fileURL(pathName: String(latestPathName))
    }
    return nil
  }

  private func getStoredPathNames() throws -> [String] {
    let directoryContents = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
    let offsets = directoryContents.map { (fileURL) -> Int64 in
      let fileURL = fileURL.deletingPathExtension()
      return Int64(fileURL.lastPathComponent)!
    }
    return offsets.sorted(by: >).map { String($0) }
  }
}
