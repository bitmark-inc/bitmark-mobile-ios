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
  weak var delegate: TransactionEventDelegate?
  static var _shared: TransactionStorage?
  static func shared() -> TransactionStorage {
    _shared = _shared ?? TransactionStorage(owner: Global.currentAccount!)
    return _shared!
  }

  // MARK: - Handlers
  override func getData() throws -> [Transaction] {
    if let txsURL = try getLatestURL() {
      let transactionsWithAsset = try TransactionsWithAsset(from: txsURL)
      Global.addAssets(transactionsWithAsset.assets)
      Global.addBlocks(transactionsWithAsset.blocks)
      return transactionsWithAsset.txs.reversed()
    }
    return [Transaction]()
  }

  /**
   Sync and merge all transactions into a file; set the latest offset as the filename
   - Parameters:
      - notifyNew: when true, notify receiveNewTransactions to update in UI
      - doRepeat: when false, make one call listTransactions API one only
   when we're sure that there are no remain transactions in next API,
   such as: in eventSubscription
   */
  override func sync(notifyNew: Bool, doRepeat: Bool = true) throws {
    DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = true }
    defer {
      DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = false }
    }

    Global.latestOffset["Transaction"]  = try getStoredPathName()
    var latestOffset = Global.latestOffset["Transaction"] ?? 0

    repeat {
      let (txs, assets, blocks) = try TransactionService.listAllTransactions(ownerNumber: owner.getAccountNumber(), at: latestOffset, direction: .later)
      guard !txs.isEmpty else { return }

      var txsWithAsset = TransactionsWithAsset(assets: assets, blocks: blocks, txs: txs)

      if notifyNew {
        Global.addAssets(txsWithAsset.assets)
        Global.addBlocks(txsWithAsset.blocks)
        DispatchQueue.main.async { [weak self] in
          self?.delegate?.receiveNewTxs(txsWithAsset.txs)
        }
      }

      let baseOffset = txs.last!.offset // the last offset is the latest offset cause response transactions is asc-offset
      let txsURL = self.fileURL(pathName: baseOffset)

      if latestOffset == 0 {
        try txsWithAsset.store(in: txsURL)
      } else {
        try mergeNewTxs(txsURL, txsWithAsset)
      }

      latestOffset = baseOffset
      Global.latestOffset["Transaction"] = latestOffset
    } while doRepeat
  }

  // Merge new bitmarks into the bitmarks file
  fileprivate func mergeNewTxs(_ newTxsURL: URL, _ txsWithAsset: TransactionsWithAsset) throws {
    guard let latestPathName = Global.latestOffset["Transaction"] else { return }
    let latestTxsURL = fileURL(pathName: latestPathName)
    var oldTxsWithAsset = try TransactionsWithAsset(from: latestTxsURL)
    try oldTxsWithAsset.merge(
      with: txsWithAsset,
      from: latestTxsURL,
      to: newTxsURL
    )
  }
}
