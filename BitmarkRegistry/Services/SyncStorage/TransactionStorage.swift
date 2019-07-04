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

    Global.latestOffset["Transaction"]  = try getStoredPathName()
    var latestOffset = Global.latestOffset["Transaction"] ?? 0

    TransactionService.listAllTransactions(ownerNumber: owner.getAccountNumber(), at: latestOffset, direction: .later, handler: { [weak self] (txs, assets, error) in
      guard let self = self else { return }
      if let error = error {
        ErrorReporting.report(error: error); return
      }

      guard let txs = txs, !txs.isEmpty, let assets = assets else { return }
      var txsWithAsset = TransactionsWithAsset(assets: assets, txs: txs)

      let baseOffset = txs.last!.offset // the last offset is the latest offset cause response transactions is asc-offset
      let txsURL = self.fileURL(pathName: baseOffset)

      do {
        if latestOffset == 0 {
          try txsWithAsset.store(in: txsURL)
        } else {
          try self.mergeNewTxs(txsURL, txsWithAsset)
        }
      } catch {
        ErrorReporting.report(error: error);
      }

      latestOffset = baseOffset
      Global.latestOffset["Transaction"] = latestOffset

      DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = false }

      /* TODO: uncomment after server fix data response
      if doRepeat {
        try? self.sync(notifyNew: notifyNew, doRepeat: doRepeat) // try? cause we surely it didn't throws exception; just want to make function signature with BitmarkStorage
      }
      */
    })
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
