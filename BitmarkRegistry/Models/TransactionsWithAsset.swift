//
//  TransactionsWithAsset.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/30/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

struct TransactionsWithAsset: Codable {
  var assets: [Asset]
  var txs: [Transaction]

  init(from txsURL: URL) throws {
    let data = try Data(contentsOf: txsURL)
    let jsonDecoder = JSONDecoder()
    self = try jsonDecoder.decode(TransactionsWithAsset.self, from: data)
  }

  init(assets: [Asset], txs: [Transaction]) {
    self.assets = assets
    self.txs = txs
  }

  mutating func store(in txsURL: URL) throws {
    let jsonEncoder = JSONEncoder()
    #if IOS_SIMULATOR
      jsonEncoder.outputFormatting = .prettyPrinted
    #endif
    let jsonData = try jsonEncoder.encode(self)
    try jsonData.write(to: txsURL, options: .atomic)
  }

  mutating func merge(with other: TransactionsWithAsset , from txsURL: URL, to newTxsURL: URL) throws {
    self.assets += other.assets
    self.assets.removeDuplicates()
    self.txs += other.txs
    self.txs.removeObsoleteTxs()

    try store(in: txsURL)
    try FileManager.default.moveItem(at: txsURL, to: newTxsURL)
  }
}
