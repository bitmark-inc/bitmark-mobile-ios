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

  typealias TransactionHandler = ([Transaction]?, Error?) -> Void
  typealias TransactionAssetHandler = ([Transaction]?, [Asset]?, Error?) -> Void

  static func listAllTransactions(of bitmarkId: String, handler: @escaping TransactionHandler) {
    let transactionQuery = Transaction.newTransactionQueryParams()
                                      .referencedBitmark(bitmarkID: bitmarkId)
                                      .pending(true)
    Transaction.list(params: transactionQuery) { (txs, assets, error) in
      handler(txs, error)
    }
  }

  static func listAllTransactions(ownerNumber: String, at fromOffset: Int64, direction: QueryDirection, handler: @escaping TransactionAssetHandler) {
    do {
      let txQuery = try Transaction.newTransactionQueryParams()
                                   .loadAsset(true)
                                   .limit(size: 100)
                                   .ownedByWithTransient(ownerNumber)
                                   .at(fromOffset)
                                   .to(direction: direction)
                                   .pending(true)
      Transaction.list(params: txQuery) { (txs, assets, error) in
        handler(txs, assets, error)
      }
    } catch {
      handler(nil, nil, error)
    }
  }
}
