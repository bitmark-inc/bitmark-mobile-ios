//
//  TransactionService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/17/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class TransactionService {

  typealias TransactionHandler = ([Transaction]?, [Block]?, Error?) -> Void
  typealias TransactionAsset = ([Transaction], [Asset], [Block])

  static func listAllTransactions(of bitmarkId: String, handler: @escaping TransactionHandler) {
    let transactionQuery = Transaction.newTransactionQueryParams()
                                      .referencedBitmark(bitmarkID: bitmarkId)
                                      .pending(true)
    Transaction.list(params: transactionQuery) { (txs, _, blocks, error) in
      handler(txs, blocks, error)
    }
  }

  static func listAllTransactions(ownerNumber: String, at fromOffset: Int64, direction: QueryDirection)  throws -> TransactionAsset {
    let txQuery = try Transaction.newTransactionQueryParams()
                                 .loadAsset(true)
                                 .loadBlock(true)
                                 .limit(size: 100)
                                 .ownedByWithTransient(ownerNumber)
                                 .at(fromOffset)
                                 .to(direction: direction)
                                 .pending(true)

    let (txs, assets, blocks) = try Transaction.list(params: txQuery)
    return (txs, assets ?? [Asset](), blocks ?? [Block]())
  }
}
