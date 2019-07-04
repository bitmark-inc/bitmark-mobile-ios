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

  lazy var downloadingFolderPath: URL = {
    let directoryURL = URL(
      fileURLWithPath: owner.getAccountNumber() + "/assets/" + assetId + "/downloading",
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

      if let error = error {
        ErrorReporting.report(error: error)
        return
      }

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
        ErrorReporting.report(error: error)
      }
    }
  }

  func getDownloadedFileURL(completion: @escaping (URL?, Error?) -> Void) {
    //  return local asset file if it's existed
    if let assetFileURL = try? getAssetFile() {
      completion(assetFileURL, nil)
      return
    }

    getSenderAccountNumber { [weak self] (senderAccountNumber, error) in
      guard let self = self else { return }
      if let error = error {
        completion(nil, error); return
      }

      guard let senderAccountNumber = senderAccountNumber else { return }
      self.downloadFileFromCourierServer(senderAccountNumber: senderAccountNumber, completion: { (downloadedFileURL, error) in
          if let error = error {
            completion(nil, error); return
          }

          completion(downloadedFileURL, nil)
        }
      )
    }
  }

  func getSenderAccountNumber(completion: @escaping (String?, Error?) -> Void) {
    FileCourierServer.getDownloadableAssets(receiver: owner) { [weak self] (downloadableFileIds, error) in
      guard let self = self else { return }
      guard error == nil else { completion(nil, error); return }

      if let downloadableFileIds = downloadableFileIds, !downloadableFileIds.isEmpty,
        let downloadableFileInfo = downloadableFileIds.first(where: { $0.contains(self.assetId) }),
        let senderAccountNumber = downloadableFileInfo.split(separator: "/").last {
          completion(String(senderAccountNumber), nil)
      } else {
        let error = Global.appError(errorCode: 401, message: "user does not have permission to access asset file in FileCourierServer")
        completion(nil, error)
      }
    }
  }

  func downloadFileFromCourierServer(senderAccountNumber: String, completion: @escaping (URL?, Error?) -> Void) {
    AccountKeyService.getEncryptionPublicKey(accountNumber: senderAccountNumber) { [weak self] (senderPublicKey, error) in
      guard let self = self else { return }
      guard let senderPublicKey = senderPublicKey else { return }
      FileCourierServer.downloadFileFromCourierServer(
        assetId: self.assetId, receiver: self.owner,
        senderAccountNumber: senderAccountNumber, senderPublicKey: senderPublicKey, completion: { (responseData, error) in

        if let error = error {
          ErrorReporting.report(error: error)
          return
        }

        guard let responseData = responseData else { return }
        do {
          let assetEncryption = try AssetEncryption(
            from: responseData.sessionData, receiverAccount: self.owner, senderEncryptionPublicKey: senderPublicKey)
          let decryptedData = try assetEncryption.decryptData(responseData.encryptedFileData)
          let downloadedFileURL = self.downloadedFolderURL.appendingPathComponent(responseData.filename)

          try decryptedData.write(to: downloadedFileURL)

          completion(downloadedFileURL, nil)
        } catch {
          completion(nil, error)
        }
      })
    }
  }

  // MARK: Support Functions
  func getAssetFile() throws -> URL {
    let directoryContents = try FileManager.default.contentsOfDirectory(at: downloadedFolderURL, includingPropertiesForKeys: nil)
    return directoryContents[0]
  }
}
