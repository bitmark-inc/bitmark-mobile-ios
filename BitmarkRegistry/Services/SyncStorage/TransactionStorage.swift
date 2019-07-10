//
//  TransactionStorage.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/30/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class TransactionStorage: SyncStorageBase<Transaction> {

  // MARK: - Properties
  weak var delegate: TransactionsViewController?
  static var _shared: TransactionStorage?
  static func shared() -> TransactionStorage {
    _shared = _shared ?? TransactionStorage(owner: Global.currentAccount!)
    return _shared!
  }

  // MARK: - Handlers
  override func getData() throws -> [Transaction] {
    if let txsURL = try getLatestURL() {
      let transactionsWithAsset = try TransactionsWithRelative(from: txsURL)
      Global.addAssets(transactionsWithAsset.assets)
      Global.addBlocks(transactionsWithAsset.blocks)
      return transactionsWithAsset.txs.reversed()
    }
    return [Transaction]()
  }

  override func syncData(at latestOffset: Int64, notifyNew: Bool) throws -> Int64? {
    let (txs, assets, blocks) = try TransactionService.listAllTransactions(ownerNumber: owner.getAccountNumber(), at: latestOffset, direction: .later)
    guard !txs.isEmpty else { return nil }

    var txsWithRelative = TransactionsWithRelative(assets: assets, blocks: blocks, txs: txs)

    if notifyNew {
      Global.addAssets(txsWithRelative.assets)
      Global.addBlocks(txsWithRelative.blocks)
      DispatchQueue.main.async { [weak self] in
        self?.delegate?.receiveNewRecords(txsWithRelative.txs)
      }
    }

    let baseOffset = txs.last!.offset // the last offset is the latest offset cause response transactions is asc-offset
    let txsURL = self.fileURL(pathName: baseOffset)

    if latestOffset == 0 {
      try txsWithRelative.store(in: txsURL)
    } else {
      try mergeNewTxs(txsURL, txsWithRelative)
    }
    return baseOffset
  }

  // Merge new bitmarks into the bitmarks file
  fileprivate func mergeNewTxs(_ newTxsURL: URL, _ txsWithAsset: TransactionsWithRelative) throws {
    guard let latestPathName = Global.latestOffset["Transaction"] else { return }
    let latestTxsURL = fileURL(pathName: latestPathName)
    var oldTxsWithAsset = try TransactionsWithRelative(from: latestTxsURL)
    try oldTxsWithAsset.merge(
      with: txsWithAsset,
      from: latestTxsURL,
      to: newTxsURL
    )
  }
}
