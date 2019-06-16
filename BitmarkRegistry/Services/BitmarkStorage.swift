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
  let pathExtension = "json"
  let minimumSize = 50_000 // about 50 KB

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
    if let bitmarksURL = try getLatestBitmarksURL() {
      let bitmarksWithAsset = try BitmarksWithAsset(from: bitmarksURL)
      Global.addAssets(bitmarksWithAsset.assets)
      return bitmarksWithAsset.bitmarks.reversed()
    }
    return [Bitmark]()
  }

  func sync() throws {
    Global.storedBitmarksPathNames = try getStoredPathNames()
    let latestPathName = Global.storedBitmarksPathNames.first
    var latestOffset = latestPathName != nil ? Int64(latestPathName!)! : 0
    // Only need to connect bitmarks for the first
    var willMergeBitmarksInLatestFile = latestOffset != 0

    repeat {
      let (bitmarks, assets) = try BitmarkService.listAllBitmarksWithAsset(owner: owner, at: latestOffset, direction: .later)
      let bitmarksWithAsset = BitmarksWithAsset(assets: assets, bitmarks: bitmarks)

      guard bitmarks.count > 0 else { break }

      let baseOffset = bitmarks.sorted(by: { $0.offset > $1.offset }).first!.offset
      let bitmarksURL = fileURL(pathName: String(baseOffset))

      if willMergeBitmarksInLatestFile {
        try mergeNewBitmarks(bitmarksURL, bitmarksWithAsset)
        // only need to merge for first limited result;
        // because if bitmarks list exists the next limited result, the latest file is large enough (cause it was merged with the first limited result)
        willMergeBitmarksInLatestFile = false
      } else {
        try bitmarksWithAsset.store(in: bitmarksURL)
      }

      latestOffset = baseOffset
      Global.storedBitmarksPathNames.insert(String(latestOffset), at: 0)
    } while true
  }

  // Merge new bitmarks into the bitmarks file is having small size / number of bitmarks
  // to avoid many small-size files when user sync regularly
  fileprivate func mergeNewBitmarks(_ newBitmarksURL: URL, _ bitmarksWithAsset: BitmarksWithAsset) throws {
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

  // MARK: - Support Functions
  fileprivate func getSize(for url: URL) throws -> UInt64? {
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    return attributes[.size] as? UInt64 ?? nil
  }

  fileprivate func fileURL(pathName: String) -> URL {
    return directoryURL.appendingPathComponent(pathName).appendingPathExtension(pathExtension)
  }

  fileprivate func getLatestBitmarksURL() throws -> URL? {
    Global.storedBitmarksPathNames = try getStoredPathNames()
    if let latestPathName = Global.storedBitmarksPathNames.first {
      return fileURL(pathName: String(latestPathName))
    }
    return nil
  }

  fileprivate func getStoredPathNames() throws -> [String] {
    let directoryContents = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
    let offsets = directoryContents.map { (fileURL) -> Int64 in
      let fileURL = fileURL.deletingPathExtension()
      return Int64(fileURL.lastPathComponent)!
    }
    return offsets.sorted(by: >).map { String($0) }
  }
}
