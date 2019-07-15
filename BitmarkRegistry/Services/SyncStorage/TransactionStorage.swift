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
  let ignoreDeleteTxPredicate: NSPredicate = {
    let zeroAccountNumber = Credential.valueForKey(keyName: Constant.InfoKey.zeroAddress)
    return NSPredicate(format: "owner != %@", zeroAccountNumber)
  }()

  lazy var ignoreUnownedTxPredicate: NSPredicate = {
    let accountNumber = owner.getAccountNumber()
    return NSPredicate(format: "(owner == %@ || previousOwner == %@)", accountNumber, accountNumber)
  }()

  // MARK: - Handlers
  func getData() throws -> Results<TransactionR> {
    return try ownerRealm().objects(TransactionR.self)
                           .filter(ignoreDeleteTxPredicate)
                           .filter(ignoreUnownedTxPredicate)
                           .sorted(byKeyPath: "offset", ascending: false)
  }

  func syncData(for bitmarkR: BitmarkR) throws {
    let realm = try ownerRealm()
    var latestOffset: Int64 = 0

    repeat {
      let (txs, blocks) = try TransactionService.listAllTransactions(of: bitmarkR.id, at: latestOffset, direction: .later)
      guard !txs.isEmpty else { return }

      try storeData(in: realm, txs: txs, relations: (assets: nil, blocks: blocks))
      latestOffset = txs.last!.offset
      if txs.count < 100 { break }
    } while true
  }

  override func syncData() throws {
    let backgroundOwnerRealm = try ownerRealm()
    var latestOffset = getLatestOffsetR(in: backgroundOwnerRealm)?.offset ?? 0

    repeat {
      let (txs, assets, blocks) = try TransactionService.listAllTransactions(ownerNumber: owner.getAccountNumber(), at: latestOffset, direction: .later)
      guard !txs.isEmpty else { return }

      try storeData(in: backgroundOwnerRealm, txs: txs, relations: (assets: assets, blocks: blocks))
      latestOffset = txs.last!.offset
      if txs.count < 100 { break }
    } while true

    try backgroundOwnerRealm.write {
      backgroundOwnerRealm.add(LatestOffsetR(value: ["Transaction", latestOffset]), update: .modified)
    }
  }

  fileprivate func storeData(in realm: Realm, txs: [Transaction], relations: (assets: [Asset]?, blocks: [Block])) throws {
    try txs.forEach { (tx) in
      let txR = TransactionR(tx: tx)
      try realm.write {
        if let assets = relations.assets, let asset = assets.first(where: { $0.id == tx.asset_id }) {
          let assetR = AssetR(asset: asset)
          realm.add(assetR, update: .modified)
          txR.assetR = assetR
        }

        if let block = relations.blocks.first(where: { $0.number == tx.block_number }) {
          let blockR = BlockR(block: block)
          realm.add(blockR, update: .modified)
          txR.blockR = blockR
        }

        realm.add(txR, update: .modified)
      }
    }
  }
}
