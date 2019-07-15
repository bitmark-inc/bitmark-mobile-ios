//
//  TransactionStorage.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/30/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK
import RealmSwift

class TransactionStorage: SyncStorageBase<Transaction> {

  // MARK: - Properties
  static var _shared: TransactionStorage?
  static func shared() -> TransactionStorage {
    _shared = _shared ?? TransactionStorage(owner: Global.currentAccount!)
    return _shared!
  }
  // Ignore if owner of transaction is zeroAccountNumber - delete bitmark
  let filterRealmPredicate: NSPredicate = {
    let zeroAccountNumber = Credential.valueForKey(keyName: Constant.InfoKey.zeroAddress)
    return NSPredicate(format: "owner != %@", zeroAccountNumber)
  }()

  // MARK: - Handlers
  func getData() throws -> Results<TransactionR> {
    return try ownerRealm().objects(TransactionR.self)
                           .filter(filterRealmPredicate)
                           .sorted(byKeyPath: "offset", ascending: false)
  }

  override func syncData() throws {
    let backgroundOwnerRealm = try ownerRealm()
    var latestOffset = getLatestOffsetR(in: backgroundOwnerRealm)?.offset ?? 0

    repeat {
      let (txs, assets, blocks) = try TransactionService.listAllTransactions(ownerNumber: owner.getAccountNumber(), at: latestOffset, direction: .later)
      guard !txs.isEmpty else { return }

      try txs.forEach { (tx) in
        var assetR: AssetR?
        if let asset = assets.first(where: { $0.id == tx.asset_id }) {
          assetR = AssetR(asset: asset)
        }

        var blockR: BlockR?
        if let block = blocks.first(where: { $0.number == tx.block_number }) {
          blockR = BlockR(block: block)
        }

        let txR = TransactionR(tx: tx, assetR: assetR, blockR: blockR)
        try backgroundOwnerRealm.write {
          backgroundOwnerRealm.add(txR, update: .modified)
        }
      }
      latestOffset = txs.last!.offset
      if txs.count < 100 { break }
    } while true

    try backgroundOwnerRealm.write {
      backgroundOwnerRealm.add(LatestOffsetR(value: ["Transaction", latestOffset]), update: .modified)
    }
  }
}
