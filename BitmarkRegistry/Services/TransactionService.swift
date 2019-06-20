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

  static func listAllTransactions(of bitmarkId: String, handler: @escaping TransactionHandler) {
    let transactionQuery = Transaction.newTransactionQueryParams()
                                      .referencedBitmark(bitmarkID: bitmarkId)
                                      .pending(true)
    Transaction.list(params: transactionQuery) { (transactions, assets, error) in
      handler(transactions, error)
    }
  }
}
