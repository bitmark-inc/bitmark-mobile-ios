//
//  BitmarksWithAsset.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/5/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
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

  func store(in bitmarksURL: URL) throws {
    let jsonEncoder = JSONEncoder()
    #if IOS_SIMULATOR
      jsonEncoder.outputFormatting = .prettyPrinted
    #endif
    let jsonData = try jsonEncoder.encode(self)
    try jsonData.write(to: bitmarksURL, options: .atomic)
  }
}
