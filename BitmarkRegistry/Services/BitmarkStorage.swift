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
      return bitmarksWithAsset.bitmarks
    }
    return [Bitmark]()
  }

  func sync() throws {
    Global.storedBitmarksPathNames = try getStoredPathNames()
    let latestPathName = Global.storedBitmarksPathNames.first
    var latestOffset = latestPathName != nil ? Int64(latestPathName!)! : 0

    repeat {
      let (bitmarks, assets) = try BitmarkService.listAllBitmarksWithAsset(owner: owner, at: latestOffset, direction: .later)
      let bitmarksWithAsset = BitmarksWithAsset(assets: assets, bitmarks: bitmarks)

      guard bitmarks.count > 0 else { break }

      let baseOffset = bitmarks.sorted(by: { $0.offset > $1.offset }).first!.offset
      let bitmarksURL = fileURL(pathName: String(baseOffset))

      try bitmarksWithAsset.store(in: bitmarksURL)

      latestOffset = baseOffset
      Global.storedBitmarksPathNames.insert(String(latestOffset), at: 0)
    } while true
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
