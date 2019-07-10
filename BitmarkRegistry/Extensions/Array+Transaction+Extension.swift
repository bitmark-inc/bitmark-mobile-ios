//
//  Array+Transaction+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/30/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

extension Array where Iterator.Element == Transaction {
  func firstIndexWithId(_ txId: String) -> Int? {
    return self.firstIndex(where: { $0.id == txId })
  }

  /** - Returns: the unique asc-offset bitmarks */
  mutating func removeObsoleteTxs() {
    let descTxs = self.sorted(by: { $0.offset > $1.offset })
    self = descTxs.reduce(into: [Transaction](), { (txs, tx) in
      if txs.firstIndexWithId(tx.id) == nil {
        txs.prepend(tx)
      }
    })
  }
}
