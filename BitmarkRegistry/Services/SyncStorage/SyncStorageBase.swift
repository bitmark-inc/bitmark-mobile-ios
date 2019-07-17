//
//  SyncStorage.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/30/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK
import RealmSwift

class SyncStorageBase<Item> {

  // MARK: - Properties
  let owner: Account

  // Get/create realm in documentURL for current account number
  func ownerRealm() throws -> Realm {
    let userConfiguration = try RealmConfig.user(owner.getAccountNumber()).configuration()
    return try Realm(configuration: userConfiguration)
  }

  lazy var serialSyncQueue: DispatchQueue = {
    return DispatchQueue(label: "com.bitmark.registry.sync\(Item.self)Queue")
  }()

  lazy var itemClassName = {
    return String(describing: Item.self)
  }()

  func latestOffsetKey() -> String { return owner.getAccountNumber() + "_" + itemClassName }

  // MARK: - Init
  init(owner: Account) {
    self.owner = owner
  }

  /**
   - If data no exist in local storage:
      * execute sync all bitmarks from beginning (without notifyNew cause we already wait for sync all and display data)
      * get and returns data to display in UI
   - If data exists in local storage:
      * load existing data into UI
      * execute sync in background and update bitmark rows if any change
   */
  func firstLoad(handler: @escaping (Error?) -> Void) throws {
    if getLatestOffset() == nil {
      asyncUpdateInSerialQueue() { (executeSyncResult) in
        do {
          try executeSyncResult()
          DispatchQueue.main.async { handler(nil) }
        } catch {
          DispatchQueue.main.async { handler(error) }
        }
      }
    } else {
      handler(nil)
      asyncUpdateInSerialQueue(completion: nil)
    }
  }

  func syncData() throws {
    fatalError("syncData has not been implemented")
  }

  typealias throwsFunction = () throws -> Void
  func asyncUpdateInSerialQueue(completion: ((_ inner: throwsFunction) -> Void)?) {
    serialSyncQueue.async { [weak self] in
      do {
        DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = true }
        defer {
          DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = false }
        }
        try self?.syncData()
        completion?({})
      } catch {
        ErrorReporting.report(error: error)
        completion?({ throw error })
      }
    }
  }

  // MARK: - Support Functions
  open func getLatestOffset() -> Int64? {
    return UserDefaults.standard.value(forKey: latestOffsetKey()) as? Int64
  }

  open func storeLatestOffset(value: Int64) {
    UserDefaults.standard.set(value, forKey: latestOffsetKey())
  }
}
