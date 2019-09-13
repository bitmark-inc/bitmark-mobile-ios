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
import RxSwift
import RxAlamofire

class AssetFileService {

  // MARK: Properties
  let owner: Account
  let assetId: String
  let bag = DisposeBag()

  lazy var encryptedFolderURL: URL = {
    let directoryURL = URL(
      fileURLWithPath: owner.getAccountNumber() + "/encrypted-assets/" + assetId,
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
  /**
   if current user has already uploaded the file into fileCourier: => update access of the file (case 1)
   otherwise, upload new file into fileCourier (case 2)
   */
  func transferFile(to receiverAccountNumber: String, assetFilename: String?) -> Completable {
    ErrorReporting.breadcrumbs(info: "sender: \(owner.getAccountNumber())", category: .transferFile)
    ErrorReporting.breadcrumbs(info: "receiver: \(receiverAccountNumber)", category: .transferFile)
    ErrorReporting.breadcrumbs(info: "assetId: \(assetId)", category: .transferFile)

    let receiverPubKeyObservable = AccountKeyService.getEncryptionPublicKey(accountNumber: receiverAccountNumber)
    let checkFileExistenceObservable = FileCourierService.checkFileExistence(senderAccountNumber: owner.getAccountNumber(), assetId: assetId)

    return Observable.zip(receiverPubKeyObservable, checkFileExistenceObservable)
      .flatMap({ [weak self] (receiverPubKey, currentSessionData) -> Completable in
        guard let self = self else { return Completable.never() }
        if let currentSessionData = currentSessionData {  // case 1
          return try self.updateAccessFile(receiverAccountNumber, receiverPubKey, with: currentSessionData)
        } else { // case 2
          return self.getDownloadedFileURL(assetFilename: assetFilename)
            .flatMap({ [weak self] (assetFileURL) -> Completable in
              guard let self = self else { return Completable.never() }
              return try self.uploadFile(assetFileURL, receiverAccountNumber, receiverPubKey)
            })
            .asCompletable()
        }
      })
      .asCompletable()
  }

  fileprivate func updateAccessFile(_ receiverAccountNumber: String, _ receiverPubKey: Data, with currentSessionData: SessionData) throws -> Completable {
    ErrorReporting.breadcrumbs(info: "get sessionData and updateAccessFile", category: .updateAccessFile)

    let assetEncryption = try AssetEncryption(
      from: currentSessionData,
      receiverAccount: owner, senderEncryptionPublicKey: owner.publicKey
    )
    let receiverSessionData = try SessionData.createSessionData(
      sender: owner,
      sessionKey: assetEncryption.key, algorithm: currentSessionData.algorithm,
      receiverPublicKey: receiverPubKey
    )

    return FileCourierService.updateAccessFile(
      assetId: assetId,
      sender: owner,
      receiverAccountNumber: receiverAccountNumber, receiverSessionData: receiverSessionData
    )
  }

  fileprivate func uploadFile(_ assetFileURL: URL, _ receiverAccountNumber: String, _ receiverPubKey: Data) throws -> Completable {
    ErrorReporting.breadcrumbs(info: "encryptFile and uploadFile", category: .uploadFile)

    let assetFilename = assetFileURL.lastPathComponent
    let encryptedFileURL = encryptedFolderURL.appendingPathComponent(assetFilename)

    let (senderSessionData, receiverSessionData) = try BitmarkFileUtil.encryptFile(
      fileURL: assetFileURL, destinationURL: encryptedFileURL,
      sender: owner, receiverPublicKey: receiverPubKey
    )

    return FileCourierService.uploadFile(
      assetId: assetId, encryptedFileURL: encryptedFileURL,
      sender: owner, senderSessionData: senderSessionData,
      receiverAccountNumber: receiverAccountNumber, receiverSessionData: receiverSessionData
    )
  }

  /**
   - Return local asset file if it's existed
      * when filename was stored in Realm; we use it to parse fileURL and download the file (1)
      * when filename is empty in Realm (in case the realm data has not synced with data storage);
        we get filename from data storage and work as above case (2)
   - otherwise, download file from file courier and return (3)
   */
  func getDownloadedFileURL(assetFilename: String?) -> Observable<URL> {
    ErrorReporting.breadcrumbs(info: "getDownloadedFileURL", category: .downloadFile)

    if let assetFilename = assetFilename { // 1
      let assetFileURL = iCloudService.shared.parseAssetFileURL(assetFilename)
      return Single<URL>.create { (single) -> Disposable in
        iCloudService.shared.newDownloadFileObservable
          .do(afterNext: { (fileURL) in
            guard fileURL == assetFileURL else { return }
            iCloudService.shared.saveDataRecord(assetId: self.assetId, filename: assetFilename)
          })
          .subscribe(
            onNext: { single(.success($0)) },
            onError: { single(.error($0)) }
          ).disposed(by: self.bag)
        iCloudService.shared.downloadFile(fileURL: assetFileURL)

        return Disposables.create()
      }
      .asObservable()
    } else {
      return iCloudService.shared.getFilenameFromiCloudObservable(assetId: assetId)
        .flatMap({ [weak self] (assetFilename) -> Observable<URL> in
          guard let self = self else { return Observable.empty() }
          return assetFilename.isNilOrEmpty
            ? self.downloadFileFromFileCourier() // 3
            : self.getDownloadedFileURL(assetFilename: assetFilename) // 2
        })
    }
  }

  typealias ResponseData = (sessionData: SessionData, filename: String, encryptedFileData: Data)
  func downloadFileFromFileCourier() -> Observable<URL> {
    ErrorReporting.breadcrumbs(info: "downloadFileFromFileCourier", category: .downloadFile)

    let senderAccountnumberObservable = FileCourierService.getDownloadableAssets(receiver: self.owner)
      .flatMap { self.getSenderAccountNumber(from: $0) }
      .share(replay: 1)

    let senderPublicKeyObservable = senderAccountnumberObservable
      .flatMap { AccountKeyService.getEncryptionPublicKey(accountNumber: $0) }
      .share(replay: 1)

    let downloadedFileDataObservable = Observable.zip(senderAccountnumberObservable, senderPublicKeyObservable)
      .flatMap({ [weak self] (senderAccountNumber, senderPublicKey) -> Observable<ResponseData> in
        guard let self = self else { return Observable.empty() }
        return FileCourierService.downloadFile(
          assetId: self.assetId, receiver: self.owner,
          senderAccountNumber: senderAccountNumber,
          senderPublicKey: senderPublicKey
        )
      })

    return Observable.zip(senderAccountnumberObservable, senderPublicKeyObservable, downloadedFileDataObservable)
      .flatMap { [weak self] (senderAccountNumber, senderPublicKey, fileResponseData) -> Observable<URL> in
        guard let self = self else { return Observable.empty() }

        let assetEncryption = try AssetEncryption(
          from: fileResponseData.sessionData, receiverAccount: self.owner, senderEncryptionPublicKey: senderPublicKey)
        let decryptedData = try assetEncryption.decryptData(fileResponseData.encryptedFileData)
        let assetFilename = fileResponseData.filename
        let downloadedFileURL = iCloudService.shared.parseAssetFileURL(assetFilename)
        try decryptedData.write(to: downloadedFileURL)
        iCloudService.shared.saveDataRecord(assetId: self.assetId, filename: assetFilename)

        FileCourierService.deleteAccessFile(
          assetId: self.assetId,
          senderAccountNumber: senderAccountNumber, receiverAccountNumber: self.owner.getAccountNumber()
        )
        .subscribe()
        .disposed(by: self.bag)

        return Observable.just(downloadedFileURL)
      }
  }

  func getSenderAccountNumber(from downloadableFileIds: [String]) -> Observable<String> {
    ErrorReporting.breadcrumbs(info: "getSenderAccountNumber from downloadableFileIds: \(downloadableFileIds)", category: .downloadFile)

    if !downloadableFileIds.isEmpty,
      let downloadableFileInfo = downloadableFileIds.first(where: { $0.contains(self.assetId) }),
      let senderAccountNumber = downloadableFileInfo.split(separator: "/").last {
      return Observable.just(String(senderAccountNumber))
    } else {
      let error = Global.appError(errorCode: 401, message: "user does not have permission to access asset file in FileCourierServer")
      return Observable.error(error)
    }
  }
}
