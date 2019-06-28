//
//  AssetFileService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/1/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class AssetFileService {

  // MARK: Properties
  var owner: Account
  var assetId: String

  lazy var downloadedFolderURL: URL = {
    let directoryURL = URL(
      fileURLWithPath: owner.getAccountNumber() + "/assets/" + assetId + "/downloaded",
      relativeTo: FileManager.sharedDirectoryURL
    )
    try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    return directoryURL
  }()

  // MARK: Init
  init(owner: Account, assetId: String) {
    self.owner = owner
    self.assetId = assetId
  }

  // MARK: Handlers
  func moveFileToAppStorage(fileURL: URL) throws {
    try BitmarkFileUtil.moveFile(from: fileURL, toFolder: downloadedFolderURL)
  }
}
