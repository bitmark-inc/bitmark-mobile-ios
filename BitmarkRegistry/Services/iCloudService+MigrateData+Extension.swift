//
//  iCloudService+Extension+MigrationData.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

extension iCloudService {

  func migrateFileData() {
    ErrorReporting.breadcrumbs(info: "Migrate File Data for \(user.getAccountNumber())", category: .MigrationData, traceLog: true)
    do {
      try migrateDataFromOldVersion()
      try migrateDataFromLocalToICloud()
      Global.log.info("Finish migrateFileData")
    } catch {
      ErrorReporting.report(error: error)
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
    ErrorReporting.breadcrumbs(info: "migrateDataFromOldVersion", category: .MigrationData, traceLog: true)

    let userAccountNumber = user.getAccountNumber()
    guard let userStorage = FileManager.sharedDirectoryURL?.appendingPathComponent(userAccountNumber) else { return }
    let assetsFolderStorage = userStorage.appendingPathComponent("assets")
    guard FileManager.default.fileExists(atPath: assetsFolderStorage.path) else { return }

    var assetIdFolders = try ls(in: assetsFolderStorage, options: .skipsHiddenFiles)
    for assetIdFolder in assetIdFolders {
      let assetId = assetIdFolder.lastPathComponent

      let downloadedFileFolder = assetIdFolder.appendingPathComponent("downloaded")
      guard FileManager.default.fileExists(atPath: downloadedFileFolder.path) else {
        ErrorReporting.breadcrumbs(info: "delete \(assetIdFolder) when it has downloaded folder.", category: .MigrationData, traceLog: true)
        try FileManager.default.removeItem(at: assetIdFolder)
        continue
      }

      let downloadedFileURLs = try ls(in: downloadedFileFolder, options: .skipsHiddenFiles)
      guard downloadedFileURLs.count > 0 else {
        ErrorReporting.breadcrumbs(info: "delete \(assetIdFolder) when it has no files.", category: .MigrationData, traceLog: true)
        try FileManager.default.removeItem(at: assetIdFolder)
        continue
      }

      let downloadedFileURL = downloadedFileURLs[0]
      let filename = downloadedFileURL.lastPathComponent

      ErrorReporting.breadcrumbs(info: "store \(filename) into storage", category: .MigrationData, traceLog: true)
      if let existingFileInIcloudURL = getExistingFileInIcloudURL(userAccountNumber, assetId, filename),
         FileManager.default.fileExists(atPath: existingFileInIcloudURL.path) {
        let fileURL = parseAssetFileURL(filename)
        try FileManager.default.moveItem(at: existingFileInIcloudURL, to: fileURL)
      } else {
        try moveFileToAppStorage(fileURL: downloadedFileURL, filename: filename)
      }
      saveDataRecord(assetId: assetId, filename: filename)

      ErrorReporting.breadcrumbs(info: "remove \(assetIdFolder)", category: .MigrationData, traceLog: true)
      try FileManager.default.removeItem(at: assetIdFolder)
    }

    assetIdFolders = try ls(in: assetsFolderStorage, options: .skipsHiddenFiles)
    if assetIdFolders.count == 0 {
      ErrorReporting.breadcrumbs(info: "remove \(assetsFolderStorage)", category: .MigrationData, traceLog: true)
      try FileManager.default.removeItem(at: assetsFolderStorage)
    }
  }

  // Move local storage into icloud storage in case user just logged in iCloud account.
  func migrateDataFromLocalToICloud() throws {
    ErrorReporting.breadcrumbs(info: "migrateDataFromLocalToICloud", category: .MigrationData, traceLog: true)

    guard let _ = icloudContainer else { return }
    let documentsLocalContainer = localContainer.appendingPathComponent(user.getAccountNumber())
    guard FileManager.default.fileExists(atPath: documentsLocalContainer.path) else { return }

    let localDataURL = getDataURL(documentsLocalContainer)
    let assetWithFilenameData = try getAssetWithFilenameData(localDataURL)

    for (assetId, filename) in assetWithFilenameData {
      let localFileURL = documentsLocalContainer.appendingPathComponent(filename)
      ErrorReporting.breadcrumbs(info: "store \(filename) into icloud", category: .MigrationData, traceLog: true)
      guard FileManager.default.fileExists(atPath: localFileURL.path) else { continue }
      try storeFile(fileURL: localFileURL, filename: filename, assetId: assetId)
      try FileManager.default.removeItem(at: localFileURL)
    }

    ErrorReporting.breadcrumbs(info: "remove \(documentsLocalContainer)", category: .MigrationData, traceLog: true)
    try FileManager.default.removeItem(at: documentsLocalContainer)
  }

  fileprivate func getExistingFileInIcloudURL(_ userAccountNumber: String, _ assetId: String, _ filename: String) -> URL? {
    return icloudContainer?.appendingPathComponent(
      "\(userAccountNumber)_assets_\(assetId.hexDecodedData.base58EncodedString)_\(filename)"
    )
  }

  fileprivate func ls(in folderURL: URL, options: FileManager.DirectoryEnumerationOptions) throws -> [URL] {
    return try FileManager.default.contentsOfDirectory(
      at: folderURL, includingPropertiesForKeys: nil, options: options
    )
  }
}
