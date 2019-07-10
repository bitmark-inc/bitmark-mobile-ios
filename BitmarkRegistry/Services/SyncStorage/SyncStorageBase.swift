//
//  SyncStorage.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/30/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class SyncStorageBase<Item> {

  // MARK: - Properties
  let owner: Account
  let pathExtension = "json"
  
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
  func firstLoad(handler: @escaping ([Item]?, Error?) -> Void) throws {
    Global.latestOffset[itemClassName] = try getStoredPathName()
    if Global.latestOffset[itemClassName] == nil {
      asyncUpdateInSerialQueue(notifyNew: false) { (executeSyncResult) in
        do {
          try executeSyncResult()
          let data = try self.getData()
          DispatchQueue.main.async { handler(data, nil) }
        } catch let e {
          DispatchQueue.main.async { handler(nil, e) }
        }
      }
    } else {
      let data = try getData()
      handler(data, nil)
      asyncUpdateInSerialQueue(notifyNew: true, completion: nil)
    }
  }

  func syncData(at latestOffset: Int64, notifyNew: Bool) throws -> Int64? {
    fatalError("syncData has not been implemented")
  }

  func getData() throws -> [Item] {
    fatalError("getData has not been implemented")
  }

  typealias throwsFunction = () throws -> Void
  func asyncUpdateInSerialQueue(notifyNew: Bool, doRepeat: Bool = true, completion: ((_ inner: throwsFunction) -> Void)?) {
    serialSyncQueue.async { [weak self] in
      do {
        try self?.sync(notifyNew: notifyNew, doRepeat: doRepeat)
        completion?({})
      } catch {
        ErrorReporting.report(error: error)
        completion?({ throw error })
      }
    }
  }

  /**
   Sync and merge all bitmarks into a file; set the latest offset as the filename
   - Parameters:
   - notifyNew: when true, notify receiveNewBitmarks to update in UI
   - doRepeat: when false, make one call listBitmarks API one only
   when we're sure that there are no remain bitmarks in next API,
   such as: in eventSubscription
   */
  func sync(notifyNew: Bool, doRepeat: Bool = true) throws {
    DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = true }
    defer {
      DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = false }
    }

    Global.latestOffset[itemClassName] = try getStoredPathName()
    var latestOffset = Global.latestOffset[itemClassName] ?? 0

    repeat {
      guard let newOffset = try syncData(at: latestOffset, notifyNew: notifyNew) else { break }
      latestOffset = newOffset
      Global.latestOffset[itemClassName] = latestOffset
    } while doRepeat
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
