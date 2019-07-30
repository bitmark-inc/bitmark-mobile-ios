//
//  TransactionR.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/15/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK
import RealmSwift

class TransactionR: Object {

  // MARK: - Properties
  @objc dynamic var id: String = ""
  @objc dynamic var assetR: AssetR?
  @objc dynamic var blockR: BlockR?
  @objc dynamic var bitmarkId: String = ""
  @objc dynamic var owner: String = ""
  @objc dynamic var previousOwner: String?
  @objc dynamic var status: String = ""
  @objc dynamic var offset: Int64 = 0

  override static func primaryKey() -> String? {
    return "id"
  }

  // MARK: - Init
  convenience init(tx: Transaction) {
    self.init()
    self.id = tx.id
    self.bitmarkId = tx.bitmark_id
    self.owner = tx.owner
    self.previousOwner = tx.previous_owner
    self.status = tx.status
    self.offset = tx.offset
  }
}

// MARK: - Data Handlers
extension TransactionR {
  var confirmedAt: Date? {
    guard status == TransactionStatus.confirmed.rawValue, let blockR = blockR else { return nil }
    return blockR.createdAt
  }

  func isTransferTx() -> Bool {
    return previousOwner != nil
  }
}
