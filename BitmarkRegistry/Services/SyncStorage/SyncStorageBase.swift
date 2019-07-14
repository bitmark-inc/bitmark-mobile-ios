//
//  SyncStorage.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/30/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import RealmSwift
import BitmarkSDK

class SyncStorageBase<Item> {

  // MARK: - Properties
  let owner: Account
  let pathExtension = "json"

  func ownerRealm() throws -> Realm {
    let userConfiguration = RealmConfig.user(owner.getAccountNumber()).configuration
    return try Realm(configuration: userConfiguration)
  }

  lazy var serialSyncQueue: DispatchQueue = {
    return DispatchQueue(label: "com.bitmark.registry.sync\(Item.self)Queue")
  }()

  lazy var itemClassName = {
    return String(describing: Item.self)
  }()

  fileprivate lazy var folderName = {
    return itemClassName.lowercased() + "s" // bitmarks/transactions
  }()

  // Get/create directory in documentURL; which directory's name is current account number
  lazy var directoryURL: URL = {
    let directoryURL = URL(
      fileURLWithPath: owner.getAccountNumber() + "/" + folderName,
      relativeTo: FileManager.documentDirectoryURL
    )
    try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    return directoryURL
  }()

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
    let latestOffsetR = try ownerRealm().object(ofType: LatestOffsetR.self, forPrimaryKey: itemClassName)
    if latestOffsetR == nil {
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
  open func fileURL(pathName: Int64) -> URL {
    return directoryURL.appendingPathComponent(String(pathName))
                       .appendingPathExtension(pathExtension)
  }

  open func getStoredPathName() throws -> Int64? {
    let directoryContents = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
    let offsets = directoryContents.compactMap { (fileURL) -> Int64? in
      let fileURL = fileURL.deletingPathExtension()
      return Int64(fileURL.lastPathComponent) ?? nil
    }
    return offsets.first
  }

  open func getLatestURL() throws -> URL? {
    if let latestPathName = Global.latestOffset[itemClassName] {
      return fileURL(pathName: latestPathName)
    }
    return nil
  }
}
