//
//  BitmarkStorage.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/16/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK
import RealmSwift

class BitmarkStorage: SyncStorageBase<Bitmark> {

  // MARK: - Properties
  static var _shared: BitmarkStorage?
  static func shared() -> BitmarkStorage {
    _shared = _shared ?? BitmarkStorage(owner: Global.currentAccount!)
    return _shared!
  }

  // MARK: - Handlers
  func getData() throws -> Results<BitmarkR> {
    return try ownerRealm().objects(BitmarkR.self).sorted(byKeyPath: "offset", ascending: false)
  }

  override func syncData() throws {
    let backgroundOwnerRealm = try ownerRealm()
    var latestOffset = getLatestOffsetR(in: backgroundOwnerRealm)?.offset ?? 0

    repeat {
      let (bitmarks, assets) = try BitmarkService.listAllBitmarksWithAsset(owner: owner, at: latestOffset, direction: .later)
      guard !bitmarks.isEmpty else { return }

      try bitmarks.forEach { (bitmark) in
        guard bitmark.isValid(with: owner.getAccountNumber()) else {
          guard let invalidBitmark = backgroundOwnerRealm.object(ofType: BitmarkR.self, forPrimaryKey: bitmark.id) else { return }
          try backgroundOwnerRealm.write { backgroundOwnerRealm.delete(invalidBitmark) }
          return
        }

        var assetR: AssetR?
        if let asset = assets.first(where: { $0.id == bitmark.asset_id }) {
          assetR = AssetR(asset: asset)
        }

        let bitmarkR = BitmarkR(bitmark: bitmark, assetR: assetR)
        try backgroundOwnerRealm.write {
          backgroundOwnerRealm.add(bitmarkR, update: .modified)
        }
      }
      latestOffset = bitmarks.last!.offset
      if bitmarks.count < 100 { break }
    } while true

    try backgroundOwnerRealm.write {
      backgroundOwnerRealm.add(LatestOffsetR(value: ["Bitmark", latestOffset]), update: .modified)
    }
  }
}
