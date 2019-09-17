//
//  BitmarkR.swift
//  Bitmark
//
//  Created by Thuyen Truong on 7/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import RealmSwift

class BitmarkR: Object {

  // MARK: - Properties
  @objc dynamic var id: String = ""
  @objc dynamic var assetR: AssetR?
  @objc dynamic var headId: String = ""
  @objc dynamic var issuer: String = ""
  @objc dynamic var owner: String = ""
  @objc dynamic var status: String = ""
  @objc dynamic var offset: Int64 = 0
  @objc dynamic var createdAt: Date?
  @objc dynamic var confirmedAt: Date?
  @objc dynamic var read: Bool = false

  override static func primaryKey() -> String? {
    return "id"
  }

  // MARK: - Init
  convenience init(bitmark: Bitmark, assetR: AssetR?) {
    self.init()
    self.id = bitmark.id
    self.assetR = assetR
    self.headId = bitmark.head_id
    self.issuer = bitmark.issuer
    self.owner = bitmark.owner
    self.status = bitmark.status
    self.offset = bitmark.offset
    self.createdAt = bitmark.created_at
    self.confirmedAt = bitmark.confirmed_at
  }

  func txRs(in realm: Realm) -> Results<TransactionR> {
    return realm.objects(TransactionR.self)
                .filter("bitmarkId == %@", id)
                .sorted(byKeyPath: "offset", ascending: false)
  }
}

extension Bitmark {
  func isValid(with ownerNumber: String) -> Bool {
    return owner == ownerNumber
  }
}
