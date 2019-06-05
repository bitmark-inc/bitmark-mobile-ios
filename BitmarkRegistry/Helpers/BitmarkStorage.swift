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

  lazy var directoryURL: URL = {
    let directoryURL = URL(fileURLWithPath: owner.getAccountNumber(), relativeTo: FileManager.documentDirectoryURL)
    try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    print(directoryURL)
    return directoryURL
  }()

  init(for owner: Account) {
    self.owner = owner
  }

  func getBitmarkData(fromOffset: UInt64? = nil) throws -> [Bitmark] {
    if let latestOffset = Global.storedOffsets.first {
      let baseOffsetName = String(latestOffset)
      let bitmarksURL = directoryURL.appendingPathComponent(baseOffsetName).appendingPathExtension(pathExtension)

      let bitmarksWithAsset = try BitmarksWithAsset(from: bitmarksURL)
      Global.addAssets(bitmarksWithAsset.assets)
      return bitmarksWithAsset.bitmarks
    }
    return [Bitmark]()
  }

  func sync() throws {
    Global.storedOffsets = try getStoredOffsets()
    var latestOffset = Global.storedOffsets.first ?? 0

    repeat {
      let (bitmarks, assets) = try BitmarkService.listAllBitmarksWithAsset(owner: owner, at: latestOffset, direction: .later)
      let bitmarkWithAsset = BitmarksWithAsset(assets: assets, bitmarks: bitmarks)

      guard bitmarks.count > 0 else { break }

      let baseOffset = bitmarks.sorted(by: { $0.offset > $1.offset }).first!.offset
      let baseOffsetName = String(baseOffset)
      let bitmarksURL = directoryURL.appendingPathComponent(baseOffsetName).appendingPathExtension(pathExtension)

      try bitmarkWithAsset.store(in: bitmarksURL)

      latestOffset = baseOffset
      Global.storedOffsets.insert(latestOffset, at: 0)
    } while true
  }

  private func getStoredOffsets() throws -> [Int64] {
    let directoryContents = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
    let offsets = directoryContents.map { (fileURL) -> Int64 in
      let fileURL = fileURL.deletingPathExtension()
      return Int64(fileURL.lastPathComponent)!
    }
    return offsets.sorted(by: >)
  }
}
