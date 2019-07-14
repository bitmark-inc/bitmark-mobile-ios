//
//  AssetR.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/13/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import RealmSwift
import BitmarkSDK

class AssetR: Object {
  
  // MARK: - Properties
  @objc dynamic var id: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var fingerprint: String = ""
  @objc dynamic var registrant: String = ""
  @objc dynamic var status: String = ""
  @objc dynamic var offset: Int64 = 0
  @objc dynamic var createdAt: Date? = nil
  let metadata = List<MetadataR>()

  override static func primaryKey() -> String? {
    return "id"
  }

  // MARK: - Init
  convenience init(asset: Asset) {
    self.init()
    self.id = asset.id
    self.name = asset.name
    self.fingerprint = asset.fingerprint
    self.registrant = asset.registrant
    self.status = asset.status
    self.offset = asset.offset
    self.createdAt = asset.created_at
    asset.metadata.forEach { (key, value) in
      let metadataId = asset.id + "_" + key
      metadata.append(MetadataR(value: [metadataId, key, value]))
    }
  }
}
