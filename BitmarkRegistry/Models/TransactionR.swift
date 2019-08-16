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
  @objc dynamic var confirmedAt: Date?
  @objc dynamic var txType: String = ""

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
    self.txType = extractTxType().rawValue
  }

  convenience init(claimRequest: ClaimRequest) {
    self.init()
    self.id = claimRequest.id
    self.bitmarkId = claimRequest.info.bitmark_id
    self.owner = claimRequest.from
    self.status = claimRequest.status
    self.confirmedAt = claimRequest.created_at
    self.txType = TransactionType.claimRequest.rawValue
  }
}

// MARK: - Data Handlers
extension TransactionR {
  fileprivate func extractTxType() -> TransactionType {
    return previousOwner == nil ? .issurance : .transfer
  }
}
