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
    ErrorReporting.breadcrumbs(info: "Migrate File Data for \(user.getAccountNumber())", category: .migrationData)
    do {
      guard let isiCloudEnabled = Global.isiCloudEnabled else {
        ErrorReporting.report(message: "missing flow: missing iCloud Setting in Keychain.")
        return
      }

      try migrateDataFromOldVersion()
      if isiCloudEnabled {
        try migrateDataFromLocalToiCloud()
      }
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
    ErrorReporting.breadcrumbs(info: "migrateDataFromOldVersion", category: .migrationData)

    let userAccountNumber = user.getAccountNumber()
    guard let userStorage = FileManager.sharedDirectoryURL?.appendingPathComponent(userAccountNumber) else { return }
    let assetsFolderStorage = userStorage.appendingPathComponent("assets")
    guard FileManager.default.fileExists(atPath: assetsFolderStorage.path) else { return }

    var assetIdFolders = try ls(in: assetsFolderStorage, options: .skipsHiddenFiles)
    for assetIdFolder in assetIdFolders {
      let assetId = assetIdFolder.lastPathComponent

      let downloadedFileFolder = assetIdFolder.appendingPathComponent("downloaded")
      guard FileManager.default.fileExists(atPath: downloadedFileFolder.path) else {
        ErrorReporting.breadcrumbs(info: "delete \(assetIdFolder) when it has downloaded folder.", category: .migrationData)
        try FileManager.default.removeItem(at: assetIdFolder)
        continue
      }

      let downloadedFileURLs = try ls(in: downloadedFileFolder, options: .skipsHiddenFiles)
      guard !downloadedFileURLs.isEmpty else {
        ErrorReporting.breadcrumbs(info: "delete \(assetIdFolder) when it has no files.", category: .migrationData)
        try FileManager.default.removeItem(at: assetIdFolder)
        continue
      }

      let downloadedFileURL = downloadedFileURLs[0]
      let filename = downloadedFileURL.lastPathComponent

      ErrorReporting.breadcrumbs(info: "store \(filename) into storage", category: .migrationData)
      if let existingFileInIcloudURL = getExistingFileInIcloudURL(userAccountNumber, assetId, filename),
         FileManager.default.fileExists(atPath: existingFileInIcloudURL.path) {
        let fileURL = parseAssetFileURL(filename)
        try FileManager.default.moveItem(at: existingFileInIcloudURL, to: fileURL)
      } else {
        try moveFileToAppStorage(fileURL: downloadedFileURL, filename: filename)
      }
      saveDataRecord(assetId: assetId, filename: filename)

      ErrorReporting.breadcrumbs(info: "remove \(assetIdFolder)", category: .migrationData)
      try FileManager.default.removeItem(at: assetIdFolder)
    }

    assetIdFolders = try ls(in: assetsFolderStorage, options: .skipsHiddenFiles)
    if assetIdFolders.isEmpty {
      ErrorReporting.breadcrumbs(info: "remove \(assetsFolderStorage)", category: .migrationData)
      try FileManager.default.removeItem(at: assetsFolderStorage)
    }
  }

  // Move local storage into icloud storage in case user just logged in iCloud account.
  func migrateDataFromLocalToiCloud() throws {
    ErrorReporting.breadcrumbs(info: "migrateDataFromLocalToiCloud", category: .migrationData)

    guard iCloudContainer != nil else { return }
    let documentsLocalContainer = localContainer.appendingPathComponent(user.getAccountNumber())
    guard FileManager.default.fileExists(atPath: documentsLocalContainer.path) else { return }

    let localDataURL = getDataURL(documentsLocalContainer)
    let assetWithFilenameData = try getAssetWithFilenameData(localDataURL)

    for (assetId, filename) in assetWithFilenameData {
      let localFileURL = documentsLocalContainer.appendingPathComponent(filename)
      ErrorReporting.breadcrumbs(info: "store \(filename) into icloud", category: .migrationData)

      guard FileManager.default.fileExists(atPath: localFileURL.path) else { continue }
      try storeFile(fileURL: localFileURL, filename: filename, assetId: assetId)
      try FileManager.default.removeItem(at: localFileURL)
    }

    ErrorReporting.breadcrumbs(info: "remove \(documentsLocalContainer)", category: .migrationData)
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