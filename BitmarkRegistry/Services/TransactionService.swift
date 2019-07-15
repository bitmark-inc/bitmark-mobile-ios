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

  typealias TransactionBlock = ([Transaction], [Block])
  typealias TransactionWithRelation = ([Transaction], [Asset], [Block])

  static func listAllTransactions(of bitmarkId: String, at fromOffset: Int64, direction: QueryDirection) throws -> TransactionBlock {
    let txQuery = try Transaction.newTransactionQueryParams()
                                 .referencedBitmark(bitmarkID: bitmarkId)
                                 .loadBlock(true)
                                 .limit(size: 100)
                                 .at(fromOffset)
                                 .to(direction: direction)
                                 .pending(true)

    let (txs, _, blocks) = try Transaction.list(params: txQuery)
    return (txs , blocks ?? [Block]())
  }

  static func listAllTransactions(ownerNumber: String, at fromOffset: Int64, direction: QueryDirection)  throws -> TransactionWithRelation {
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
