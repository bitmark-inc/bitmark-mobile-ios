//
//  AssetR.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/13/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK
import RealmSwift

class AssetR: Object {
  
  // MARK: - Properties
  @objc dynamic var id: String = ""
  @objc dynamic var name: String = ""
  @objc dynamic var fingerprint: String = ""
  @objc dynamic var registrant: String = ""
  @objc dynamic var status: String = ""
  @objc dynamic var offset: Int64 = 0
  @objc dynamic var createdAt: Date? = nil
  @objc dynamic var assetFilePath: String?
  @objc dynamic var assetType: String?
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

    if let currentAccount = Global.currentAccount {
      self.assetFilePath = try? AssetFileService(owner: currentAccount, assetId: asset.id).getAssetFile()?.lastPathComponent
      self.assetType = AssetType.get(from: self).rawValue
    }

    asset.metadata.forEach { (key, value) in
      metadata.append(MetadataR(value: [key, value]))
    }
  }
}

// MARK: - Data Handlers
extension AssetR {
  func updateAssetFilePath(_ assetFilePath: String) {
    guard let currentAccount = Global.currentAccount else { return }
    do {
      let userConfiguration = try RealmConfig.user(currentAccount.getAccountNumber()).configuration()
      let userRealm = try Realm(configuration: userConfiguration)

      try userRealm.write {
        self.assetFilePath = assetFilePath.lastPathComponent
        self.assetType = AssetType.get(from: self).rawValue
      }
    } catch {
      ErrorReporting.report(error: error)
    }
  }
}
