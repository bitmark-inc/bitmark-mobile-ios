//
//  BitmarksWithAsset.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/16/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

struct BitmarksWithAsset: Codable {
  var assets: [Asset]
  var bitmarks: [Bitmark]

  init(from bitmarksURL: URL) throws {
    let data = try Data(contentsOf: bitmarksURL)
    let jsonDecoder = JSONDecoder()
    self = try jsonDecoder.decode(BitmarksWithAsset.self, from: data)
  }

  init(assets: [Asset], bitmarks: [Bitmark]) {
    self.assets = assets
    self.bitmarks = bitmarks
  }

  mutating func store(in bitmarksURL: URL, ownerNumber: String) throws {
    // Pre-validate before storing
    self.bitmarks.removeUnownedBitmarks(with: ownerNumber)

    let jsonEncoder = JSONEncoder()
    #if IOS_SIMULATOR
      jsonEncoder.outputFormatting = .prettyPrinted
    #endif
    let jsonData = try jsonEncoder.encode(self)
    try jsonData.write(to: bitmarksURL, options: .atomic)
  }

  mutating func merge(with other: BitmarksWithAsset, ownerNumber: String, from bitmarksURL: URL, to newBitmarksURL: URL) throws {
    self.assets += other.assets
    self.assets.removeDuplicates()
    self.bitmarks += other.bitmarks
    self.bitmarks.removeObsoleteBitmarks()

    try store(in: bitmarksURL, ownerNumber: ownerNumber)
    try FileManager.default.moveItem(at: bitmarksURL, to: newBitmarksURL)
  }
}
