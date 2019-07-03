//
//  AssetFileService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/1/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK
import Alamofire

class AssetFileService {

  // MARK: Properties
  let owner: Account
  let assetId: String

  lazy var downloadedFolderURL: URL = {
    let directoryURL = URL(
      fileURLWithPath: owner.getAccountNumber() + "/assets/" + assetId + "/downloaded",
      relativeTo: FileManager.sharedDirectoryURL
    )
    try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    return directoryURL
  }()

  lazy var encryptedFolderURL: URL = {
    let directoryURL = URL(
      fileURLWithPath: owner.getAccountNumber() + "/assets/" + assetId + "/encrypted",
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
    let filename = fileURL.lastPathComponent
    let destinationURL = downloadedFolderURL.appendingPathComponent(filename)

    try FileManager.default.copyItem(at: fileURL, to: destinationURL)
  }

  func transferFile(to receiverAccountNumber: String) {
    AccountKeyService.getEncryptionPublicKey(accountNumber: receiverAccountNumber) { [weak self] (receiverPublicKey, error) in
      guard let self = self else { return }

      guard error == nil else { print(error!); return }

      guard let receiverPublicKey = receiverPublicKey else { return }

      do {
        let assetFileURL = try self.getAssetFile()
        let assetFilename = assetFileURL.lastPathComponent
        let encryptedFileURL = self.encryptedFolderURL.appendingPathComponent(assetFilename)

        let (senderSessionData, receiverSessionData) = try BitmarkFileUtil.encryptFile(
          fileURL: assetFileURL, destinationURL: encryptedFileURL,
          sender: self.owner, receiverPublicKey: receiverPublicKey
        )

        FileCourierServer.updateFileToCourierServer(
          assetId: self.assetId, encryptedFileURL: encryptedFileURL,
          sender: self.owner, senderSessionData: senderSessionData,
          receiverAccountNumber: receiverAccountNumber, receiverSessionData: receiverSessionData
        )
      } catch {
        print(error)
        return
      }
    }
  }

  // MARK: Handlers
  func getAssetFile() throws -> URL {
    let directoryContents = try FileManager.default.contentsOfDirectory(at: downloadedFolderURL, includingPropertiesForKeys: nil)
    return directoryContents[0]
  }
}
