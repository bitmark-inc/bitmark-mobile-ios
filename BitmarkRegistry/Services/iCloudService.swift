//
//  iCloudService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/5/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK
import RealmSwift
import RxSwift

class iCloudService {

  // MARK: - Properties
  static var shared = iCloudService(user: Global.currentAccount!)

  var user: Account
  lazy var icloudContainer: URL? = {
    return FileManager.default.url(forUbiquityContainerIdentifier: nil)?
                      .appendingPathComponent("Documents")
  }()
  lazy var localContainer: URL = {
    return FileManager.sharedDirectoryURL ?? FileManager.documentDirectoryURL
  }()

  lazy var containerURL: URL = {
    let container: URL = (icloudContainer ?? localContainer).appendingPathComponent(user.getAccountNumber())
    try? FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
    return container
  }()
  lazy var dataURL: URL = { getDataURL(containerURL) }()

  // MARK: - Init
  init(user: Account) {
    self.user = user
  }

  func storeFile(fileURL: URL, filename: String, assetId: String) throws {
    try moveFileToAppStorage(fileURL: fileURL, filename: filename)
    saveDataRecord(assetId: assetId, filename: filename)
  }

  func moveFileToAppStorage(fileURL: URL, filename: String) throws {
    let destinationURL = containerURL.appendingPathComponent(filename)
    ErrorReporting.breadcrumbs(info: "moveFileToAppStorage: \(destinationURL.path)", category: .StoreFile, traceLog: true)

    guard !fileExists(fileURL: destinationURL) else { return }
    try FileManager.default.copyItem(at: fileURL, to: destinationURL)
  }

  func saveDataRecord(assetId: String, filename: String) {
    newDownloadFileObservable
      .subscribe(onNext: { [weak self] (fileURL) in
        guard fileURL == self?.dataURL else { return }
        self?.saveAssetInfoIntoData(assetId: assetId, filename: filename)
      })
      .disposed(by: bag)

    downloadDataFile()
  }
}

// MARK: - Support Functions
extension iCloudService {
  internal func getDataURL(_ containerURL: URL) -> URL {
    return containerURL.appendingPathComponent("data.plist")
  }
}
