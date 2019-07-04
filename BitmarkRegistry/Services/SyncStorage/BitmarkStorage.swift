//
//  BitmarkStorage.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/16/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class BitmarkStorage: SyncStorageBase<Bitmark> {

  // MARK: - Properties
  static var _shared: BitmarkStorage?
  static func shared() -> BitmarkStorage {
    _shared = _shared ?? BitmarkStorage(owner: Global.currentAccount!)
    return _shared!
  }

  // MARK: - Handlers
  override func getData() throws -> [Bitmark] {
    if let bitmarksURL = try getLatestURL() {
      let bitmarksWithAsset = try BitmarksWithAsset(from: bitmarksURL)
      Global.addAssets(bitmarksWithAsset.assets)
      return bitmarksWithAsset.bitmarks.reversed()
    }
    return [Bitmark]()
  }

  /**
   Sync and merge all bitmarks into a file; set the latest offset as the filename
   - Parameters:
      - notifyNew: when true, notify receiveNewBitmarks to update in UI
      - doRepeat: when false, make one call listBitmarks API one only
          when we're sure that there are no remain bitmarks in next API,
          such as: in eventSubscription
   */
  override func sync(notifyNew: Bool, doRepeat: Bool = true) throws {
    DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = true }
    defer {
      DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = false }
    }

    Global.latestOffset["Bitmark"] = try getStoredPathName()
    var latestOffset = Global.latestOffset["Bitmark"] ?? 0

    repeat {
      let (bitmarks, assets) = try BitmarkService.listAllBitmarksWithAsset(owner: owner, at: latestOffset, direction: .later)
      guard bitmarks.count > 0 else { break }

      var bitmarksWithAsset = BitmarksWithAsset(assets: assets, bitmarks: bitmarks)

      if notifyNew {
        Global.addAssets(bitmarksWithAsset.assets)
        DispatchQueue.main.async { [weak self] in
          self?.delegate?.receiveNewBitmarks(bitmarks)
        }
      }

      let baseOffset = bitmarks.last!.offset // the last offset is the latest offset cause response bitmarks is asc-offset
      let bitmarksURL = fileURL(pathName: baseOffset)

      if latestOffset == 0 {
        try bitmarksWithAsset.store(in: bitmarksURL, ownerNumber: owner.getAccountNumber())
      } else {
        try mergeNewBitmarks(bitmarksURL, bitmarksWithAsset)
      }

      latestOffset = baseOffset
      Global.latestOffset["Bitmark"] = latestOffset
    } while doRepeat
  }

  // Merge new bitmarks into the bitmarks file
  fileprivate func mergeNewBitmarks(_ newBitmarksURL: URL, _ bitmarksWithAsset: BitmarksWithAsset) throws {
    guard let latestPathName = Global.latestOffset["Bitmark"] else { return }
    let latestBitmarksURL = fileURL(pathName: latestPathName)
    var oldBitmarksWithAsset = try BitmarksWithAsset(from: latestBitmarksURL)
    try oldBitmarksWithAsset.merge(
      with: bitmarksWithAsset,
      ownerNumber: owner.getAccountNumber(),
      from: latestBitmarksURL,
      to: newBitmarksURL
    )
  }
}
