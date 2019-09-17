//
//  BitmarkStorage.swift
//  Bitmark
//
//  Created by Thuyen Truong on 6/16/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
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

  // Read Handlers
  func markRead(for bitmarkR: BitmarkR) throws {
    try ownerRealm().write {
      bitmarkR.read = true
    }
  }

  func hasUnread() -> Bool {
    return (try? !ownerRealm().objects(BitmarkR.self).filter("read == false").isEmpty) ?? false
  }

  override func syncData() throws {
    let backgroundOwnerRealm = try ownerRealm()
    var latestOffset = getLatestOffset() ?? 0

    repeat {
      let (bitmarks, assets) = try BitmarkService.listAllBitmarksWithAsset(owner: owner, at: latestOffset, direction: .later)
      guard !bitmarks.isEmpty else { return }

      try bitmarks.forEach { (bitmark) in
        guard bitmark.isValid(with: owner.getAccountNumber()) else {
          guard let invalidBitmark = backgroundOwnerRealm.object(ofType: BitmarkR.self, forPrimaryKey: bitmark.id) else { return }
          try backgroundOwnerRealm.write { backgroundOwnerRealm.delete(invalidBitmark) }
          return
        }

        var assetR = backgroundOwnerRealm.object(ofType: AssetR.self, forPrimaryKey: bitmark.asset_id)
        if assetR == nil, let asset = assets.first(where: { $0.id == bitmark.asset_id }) {
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

    storeLatestOffset(value: latestOffset)
  }

  func loadTxRs(for bitmarkR: BitmarkR, forceSync: Bool = false, completion: @escaping (Results<TransactionR>?, Error?) -> Void) {
    do {
      let realm = try ownerRealm()
      if forceSync || realm.object(ofType: TransactionR.self, forPrimaryKey: bitmarkR.headId) == nil ||
        realm.object(ofType: TransactionR.self, forPrimaryKey: bitmarkR.id) == nil {
        DispatchQueue.main.async {
          do {
            let realm = try self.ownerRealm()
            try TransactionStorage.shared().syncData(for: bitmarkR)
            let txRs = bitmarkR.txRs(in: realm)
            completion(txRs, nil)
          } catch {
            completion(nil, error)
          }
        }
      } else {
        let txRs = bitmarkR.txRs(in: realm)
        completion(txRs, nil)
      }
    } catch {
      completion(nil, error)
    }
  }
}
