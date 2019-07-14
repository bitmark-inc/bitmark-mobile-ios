//
//  BitmarkR.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/13/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK
import RealmSwift

class BitmarkR: Object {

  // MARK: - Properties
  @objc dynamic var id: String = ""
  @objc dynamic var assetR: AssetR?
  @objc dynamic var issuer: String = ""
  @objc dynamic var owner: String = ""
  @objc dynamic var status: String = ""
  @objc dynamic var offset: Int64 = 0
  @objc dynamic var createdAt: Date? = nil
  @objc dynamic var confirmedAt: Date? = nil

  override static func primaryKey() -> String? {
    return "id"
  }

  // MARK: - Init
  convenience init(bitmark: Bitmark, assetR: AssetR?) {
    self.init()
    self.id = bitmark.id
    self.assetR = assetR
    self.issuer = bitmark.issuer
    self.owner = bitmark.owner
    self.status = bitmark.status
    self.offset = bitmark.offset
    self.createdAt = bitmark.created_at
    self.confirmedAt = bitmark.confirmed_at
  }
}
