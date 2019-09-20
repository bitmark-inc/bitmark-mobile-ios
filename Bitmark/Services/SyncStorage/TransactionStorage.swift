//
//  TransactionStorage.swift
//  Bitmark
//
//  Created by Thuyen Truong on 6/30/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import RealmSwift
import RxSwift

class TransactionStorage: SyncStorageBase<Transaction> {

  // MARK: - Properties
  static var _shared: TransactionStorage?
  static func shared() -> TransactionStorage {
    _shared = _shared ?? TransactionStorage(owner: Global.currentAccount!)
    return _shared!
  }
  let disposeBag = DisposeBag()

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
    let sortProperties = [
      SortDescriptor(keyPath: "confirmedAt", ascending: false),
      SortDescriptor(keyPath: "offset", ascending: false)
    ]
    return try ownerRealm().objects(TransactionR.self)
                           .filter(ignoreDeleteTxPredicate)
                           .filter(ignoreUnownedTxPredicate)
                           .sorted(by: sortProperties)
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
    var latestOffset = getLatestOffset() ?? 0

    repeat {
      let (txs, assets, blocks) = try TransactionService.listAllTransactions(ownerNumber: owner.getAccountNumber(), at: latestOffset, direction: .later)
      guard !txs.isEmpty else { break }

      try storeData(in: backgroundOwnerRealm, txs: txs, relations: (assets: assets, blocks: blocks))
      latestOffset = txs.last!.offset
      if txs.count < 100 { break }
    } while true

    storeLatestOffset(value: latestOffset)

    // Sync ClaimRequest
    MusicService.listAllClaimRequests()
      .subscribe(onNext: { [weak self] (claimRequests) in
        guard let self = self else { return }
        do {
          try self.storeData(in: try self.ownerRealm(), claimRequests: claimRequests)
        } catch {
          Global.log.error(error)
        }
      }, onError: {
        Global.log.error($0)
      })
      .disposed(by: disposeBag)
  }

  fileprivate func storeData(in realm: Realm, txs: [Transaction], relations: (assets: [Asset]?, blocks: [Block])) throws {
    try txs.forEach { (tx) in
      let txR = TransactionR(tx: tx)
      try realm.write {

        var assetR = realm.object(ofType: AssetR.self, forPrimaryKey: tx.asset_id)
        if assetR == nil, let assets = relations.assets, let asset = assets.first(where: { $0.id == tx.asset_id }) {
          assetR = AssetR(asset: asset)
        }

        var blockR = realm.object(ofType: BlockR.self, forPrimaryKey: tx.block_number)
        if blockR == nil, let block = relations.blocks.first(where: { $0.number == tx.block_number }) {
          blockR = BlockR(block: block)
        }

        txR.assetR = assetR
        txR.blockR = blockR
        txR.confirmedAt = blockR?.createdAt
        realm.add(txR, update: .modified)
      }
    }
  }

  fileprivate func storeData(in realm: Realm, claimRequests: [ClaimRequest]) throws {
    try claimRequests.forEach { (claimRequest) in
      let txR = TransactionR(claimRequest: claimRequest)
      try realm.write {
        txR.assetR = realm.object(ofType: AssetR.self, forPrimaryKey: claimRequest.asset_id)
        realm.add(txR, update: .modified)
      }
    }
  }
}
