//
//  TransactionsWithAsset.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/30/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

struct TransactionsWithRelative: Codable {
  var assets: [Asset]
  var blocks: [Block]
  var txs: [Transaction]

  init(from txsURL: URL) throws {
    let data = try Data(contentsOf: txsURL)
    let jsonDecoder = JSONDecoder()
    self = try jsonDecoder.decode(TransactionsWithRelative.self, from: data)
  }

  init(assets: [Asset], blocks: [Block], txs: [Transaction]) {
    self.assets = assets
    self.blocks = blocks
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

  mutating func merge(with other: TransactionsWithRelative , from txsURL: URL, to newTxsURL: URL) throws {
    self.assets += other.assets
    self.assets.removeDuplicates()
    self.blocks += other.blocks
    self.blocks.removeDuplicates()
    self.txs += other.txs
    self.txs.removeObsoleteTxs()

    try store(in: txsURL)
    try FileManager.default.moveItem(at: txsURL, to: newTxsURL)
  }
}

extension Transaction {
  func confirmedAt() -> Date? {
    if status == TransactionStatus.confirmed.rawValue,
      let block = Global.findBlock(with: block_number) {
      return block.created_at
    }
    return nil
  }
}
