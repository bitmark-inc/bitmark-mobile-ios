//
//  iCloudService+Extension+MigrationData.swift
//  Bitmark
//
//  Created by Thuyen Truong on 8/11/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

extension iCloudService {

  func migrateFileData() {
    Global.log.info("Migrate File Data for \(user.getAccountNumber())")
    do {
      guard let isiCloudEnabled = Global.isiCloudEnabled else {
        Global.log.warning("missing flow: missing iCloud Setting in Keychain.")
        return
      }

      try migrateDataFromOldVersion()
      if isiCloudEnabled {
        try migrateDataFromLocalToiCloud()
      }
      Global.log.info("Finish migrateFileData")
    } catch {
      Global.log.error(error)
    }
  }

  /**
   In old version,
      - in local: files stores as path shared/:userAccountNumber/assets/:assetId/downloaded/:file
      - in icloud: files stores as path :assetId_:filename
   Move file into app storage (local storage or icloud storage) then remove file.
   Remove assets folder when there are no local files.
   */
  func migrateDataFromOldVersion() throws {
    Global.log.info("migrateDataFromOldVersion")

    let userAccountNumber = user.getAccountNumber()
    guard let userStorage = FileManager.sharedDirectoryURL?.appendingPathComponent(userAccountNumber) else { return }
    let assetsFolderStorage = userStorage.appendingPathComponent("assets")
    guard FileManager.default.fileExists(atPath: assetsFolderStorage.path) else { return }

    var assetIdFolders = try ls(in: assetsFolderStorage, options: .skipsHiddenFiles)
    for assetIdFolder in assetIdFolders {
      let assetId = assetIdFolder.lastPathComponent

      let downloadedFileFolder = assetIdFolder.appendingPathComponent("downloaded")
      guard FileManager.default.fileExists(atPath: downloadedFileFolder.path) else {
        Global.log.info("delete \(assetIdFolder) when it has downloaded folder.")
        try FileManager.default.removeItem(at: assetIdFolder)
        continue
      }

      let downloadedFileURLs = try ls(in: downloadedFileFolder, options: .skipsHiddenFiles)
      guard !downloadedFileURLs.isEmpty else {
        Global.log.info("delete \(assetIdFolder) when it has no files.")
        try FileManager.default.removeItem(at: assetIdFolder)
        continue
      }

      let downloadedFileURL = downloadedFileURLs[0]
      let filename = downloadedFileURL.lastPathComponent

      Global.log.info("store \(filename) into storage")
      if let existingFileInIcloudURL = getExistingFileInIcloudURL(userAccountNumber, assetId, filename),
         FileManager.default.fileExists(atPath: existingFileInIcloudURL.path) {
        let fileURL = parseAssetFileURL(filename)
        try FileManager.default.moveItem(at: existingFileInIcloudURL, to: fileURL)
      } else {
        try moveFileToAppStorage(fileURL: downloadedFileURL, filename: filename)
      }
      saveDataRecord(assetId: assetId, filename: filename)

      Global.log.info("remove \(assetIdFolder)")
      try FileManager.default.removeItem(at: assetIdFolder)
    }

    assetIdFolders = try ls(in: assetsFolderStorage, options: .skipsHiddenFiles)
    if assetIdFolders.isEmpty {
      Global.log.info("remove \(assetsFolderStorage)")
      try FileManager.default.removeItem(at: assetsFolderStorage)
    }
  }

  // Move local storage into icloud storage in case user just logged in iCloud account.
  func migrateDataFromLocalToiCloud() throws {
    Global.log.info("migrateDataFromLocalToiCloud")

    guard iCloudContainer != nil else { return }
    let documentsLocalContainer = localContainer.appendingPathComponent(user.getAccountNumber())
    guard FileManager.default.fileExists(atPath: documentsLocalContainer.path) else { return }

    let localDataURL = getDataURL(documentsLocalContainer)
    let assetWithFilenameData = try getAssetWithFilenameData(localDataURL)

    for (assetId, filename) in assetWithFilenameData {
      let localFileURL = documentsLocalContainer.appendingPathComponent(filename)
      Global.log.info("store \(filename) into icloud")

      guard FileManager.default.fileExists(atPath: localFileURL.path) else { continue }
      try storeFile(fileURL: localFileURL, filename: filename, assetId: assetId)
      try FileManager.default.removeItem(at: localFileURL)
    }

    Global.log.info("remove \(documentsLocalContainer)")
    try FileManager.default.removeItem(at: documentsLocalContainer)
  }

  fileprivate func getExistingFileInIcloudURL(_ userAccountNumber: String, _ assetId: String, _ filename: String) -> URL? {
    return iCloudContainer?.appendingPathComponent(
      "\(userAccountNumber)_assets_\(assetId.hexDecodedData.base58EncodedString)_\(filename)"
    )
  }

  fileprivate func ls(in folderURL: URL, options: FileManager.DirectoryEnumerationOptions) throws -> [URL] {
    return try FileManager.default.contentsOfDirectory(
      at: folderURL, includingPropertiesForKeys: nil, options: options
    )
  }
}
