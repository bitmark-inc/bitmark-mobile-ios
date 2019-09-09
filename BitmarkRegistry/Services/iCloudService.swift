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
import RxCocoa

enum DownloadFileError: Error {
  case NotFound
}

class iCloudService {

  // MARK: - Properties
  static var _shared: iCloudService?
  static var shared: iCloudService {
    _shared = _shared ?? iCloudService(user: Global.currentAccount!)
    return _shared!
  }

  var user: Account
  lazy var iCloudContainer: URL? = {
    return FileManager.default.url(forUbiquityContainerIdentifier: nil)?
                      .appendingPathComponent("Documents")
  }()
  lazy var localContainer: URL = {
    return FileManager.sharedDirectoryURL ?? FileManager.documentDirectoryURL
  }()

  lazy var containerURL: URL = {
    func defineContainer() -> URL {
      guard let iCloudSetting = KeychainStore.getiCloudSettingFromKeychain(user.getAccountNumber()) else {
        ErrorReporting.report(error: Global.appError(message: "missing flow: missing iCloud Setting in Keychain"))
        return localContainer
      }

      if iCloudSetting {
        guard let iCloudContainer = iCloudContainer else {
          ErrorReporting.report(error: Global.appError(message: "missing flow: iCloud enable in Bitmark but disable"))
          return localContainer
        }
        return iCloudContainer
      } else {
        return localContainer
      }
    }

    let container = defineContainer().appendingPathComponent(user.getAccountNumber())
    try? FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
    Global.log.info("ContainerURL: \(container)")
    return container
  }()
  lazy var dataURL: URL = { getDataURL(containerURL) }()

  var localAssetWithFilenameData: [String: String] = [:]
  var fileDocumentQuery: NSMetadataQuery?
  var fileDocumentUploadQuery: NSMetadataQuery!
  var serialSyncQueue: DispatchQueue = DispatchQueue(label: "com.bitmark.registry.iCloudQueue")
  var downloadFileSubject = PublishSubject<URL>()
  var uploadedAssetFileSubject = BehaviorRelay<[String]>(value: [])
  var newDownloadFileObservable: Observable<URL> {
    downloadFileSubject = PublishSubject<URL>()
    return downloadFileSubject.asObservable()
  }
  let bag = DisposeBag()
  var currentFileURL: URL!

  // MARK: - Init
  init(user: Account) {
    self.user = user

    setupUploadMetadataQuery()
  }

  // MARK: - Handlers
  static func ableToConnectiCloud() -> Bool {
    return FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil
  }

  // MARK - Sync Data File
  func setupDataFile() throws {
    guard !fileExists(fileURL: dataURL) else { return }
    ErrorReporting.breadcrumbs(info: "createDataFile", category: .StoreData, traceLog: true)
    let emptyAssetWithFilenameData: [String: String] = [:]
    let data = try JSONEncoder().encode(emptyAssetWithFilenameData)
    try data.write(to: dataURL, options: [.atomic])
    ErrorReporting.breadcrumbs(info: "Finished to createDataFile", category: .StoreData, traceLog: true)
  }

  func syncDataFromiCloud() {
    ErrorReporting.breadcrumbs(info: "syncDataFromiCloud", category: .StoreData, traceLog: true)
    DispatchQueue.global().async { [weak self] in
      guard let self = self else { return }
      self.newDownloadFileObservable
        .subscribe(onNext: { [weak self] (fileURL) in
          guard fileURL == self?.dataURL else { return }
          self?.updateAssetInfoFromData()
        })
        .disposed(by: self.bag)
      self.downloadDataFile()
    }
  }

  func updateAssetInfoFromData() {
    ErrorReporting.breadcrumbs(info: "updateAssetInfoFromData", category: .StoreData, traceLog: true)
    do {
      guard let userRealm = try RealmConfig.currentRealm() else { return }

      let assetRs = userRealm.objects(AssetR.self).filter("filename == nil OR filename == ''")
      try userRealm.write {
        for assetR in assetRs {
          guard let assetFileName = getAssetFilename(with: assetR.id)?.lastPathComponent else { continue }
          assetR.filename = assetFileName
          assetR.assetType = AssetType.get(from: assetR).rawValue
        }
      }
      ErrorReporting.breadcrumbs(info: "Finish updateAssetInfoFromData", category: .StoreData, traceLog: true)
    } catch {
      Global.log.error(error)
      ErrorReporting.report(error: error)
    }
  }

  func downloadDataFile() {
    downloadFile(fileURL: dataURL)
  }

  // MARK: - Get FileURL
  func checkUploadiCloudStatus(assetId: String) {
    getFilenameFromiCloudObservable(assetId: assetId)
      .subscribe(onNext: { [weak self] (filename) in
        guard let self = self else { return }
        guard let filename = filename else { return }
        let assetFileURL = self.parseAssetFileURL(filename)
        guard let isUploaded = self.isFileUploaded(fileURL: assetFileURL) else { return }

        if isUploaded {
          var uploadedFilenames = self.uploadedAssetFileSubject.value
          uploadedFilenames.append(assetFileURL.lastPathComponent)
          self.uploadedAssetFileSubject.accept(uploadedFilenames)
        }
      }, onError: { (error) in
        ErrorReporting.report(error: error)
      })
    .disposed(by: bag)
  }

  func parseAssetFileURL(_ filename: String) -> URL {
    return containerURL.appendingPathComponent(filename)
  }

  func getFilenameFromiCloudObservable(assetId: String) -> Observable<String?> {
    return Single<String?>.create(subscribe: { (single) -> Disposable in
      self.newDownloadFileObservable
        .subscribe(
          onNext: { [weak self] (fileURL) in
            guard fileURL == self?.dataURL else { return }
            single(.success(self?.getAssetFilename(with: assetId)))
          },
          onError: { single(.error($0)) }
        )
        .disposed(by: self.bag)
      iCloudService.shared.downloadDataFile()
      return Disposables.create()
    })
    .asObservable()
  }

  func getAssetFilename(with assetId: String) -> String? {
    if let filename = iCloudService.shared.localAssetWithFilenameData[assetId] { return filename }
    do {
      var assetWithFilenameData = try getAssetWithFilenameData()
      return assetWithFilenameData[assetId]
    } catch {
      ErrorReporting.report(error: error)
      return nil
    }
  }

  // MARK: - Store File
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

  func saveAssetInfoIntoData(assetId: String, filename: String) {
    ErrorReporting.breadcrumbs(info: "saveAssetInfoIntoData", category: .StoreFile, traceLog: true)
    serialSyncQueue.sync {
      do {
        var assetWithFilenameData = try getAssetWithFilenameData()

        guard !assetWithFilenameData.has(key: assetId) else { return }
        assetWithFilenameData[assetId] = filename
        let data = try JSONEncoder().encode(assetWithFilenameData)

        try data.write(to: dataURL, options: [.atomic])
      } catch {
        ErrorReporting.report(error: error)
      }
    }
  }

  // MARK: - Download File
  func downloadFile(fileURL: URL) {
    currentFileURL = fileURL
    guard let isFileDownloaded = isFileDownloaded(fileURL: fileURL, documentQuery: &fileDocumentQuery) else {
      ErrorReporting.breadcrumbs(info: "File \(fileURL) is not existed in icloud", category: .StoreFile, traceLog: true)
      downloadFileSubject.onError(DownloadFileError.NotFound)
      downloadFileSubject.onCompleted()
      return
    }

    if isFileDownloaded {
      downloadFileSubject.onNext(fileURL)
      downloadFileSubject.onCompleted()
    } else {
      guard let fileDocumentQuery = fileDocumentQuery else { return }
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(fileUpdate),
        name: NSNotification.Name.NSMetadataQueryDidUpdate,
        object: fileDocumentQuery
      )
      fileDocumentQuery.start()
    }
  }

  @objc func fileUpdate(notification: NSNotification) {
    guard let query = notification.object as? NSMetadataQuery,
      let fileDocumentQuery = fileDocumentQuery else { return }
    guard isValidPercent(query: query, startQuery: fileDocumentQuery) else { return }

    self.fileDocumentQuery = nil
    downloadFileSubject.onNext(currentFileURL)
    downloadFileSubject.onCompleted()
  }

  @objc func updateUploadedFiles(notification: NSNotification) {
    guard let query = notification.object as? NSMetadataQuery else { return }
    query.disableUpdates()
    defer {
      query.enableUpdates()
    }

    uploadedAssetFileSubject.accept(extractFilenames(query: query))
  }
}

// MARK: - Support Functions
extension iCloudService {
  internal func getAssetWithFilenameData(_ dataURL: URL? = nil) throws -> [String: String] {
    let dataURL = dataURL ?? self.dataURL
    guard fileExists(fileURL: dataURL) else { return [:] }
    let data = try Data(contentsOf: dataURL)
    return try JSONDecoder().decode([String : String].self, from: data)
  }

  fileprivate func isValidPercent(query: NSMetadataQuery, startQuery: NSMetadataQuery) -> Bool {
    guard query == startQuery, query.resultCount != 0,
      let item = query.result(at: 0) as? NSMetadataItem else { return false }

    let progress = item.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey)
    guard let progressValue = progress.value as? Double else { return false }
    return progressValue >= 100.0
  }

  fileprivate func extractFilenames(query: NSMetadataQuery) -> [String] {
    return (0..<query.resultCount).compactMap { (index) -> String in
      guard let item = query.result(at: index) as? NSMetadataItem,
            let fileURL = item.value(forAttribute: NSMetadataItemURLKey) as? URL else { return "" }
      return fileURL.lastPathComponent
    }
  }

  /**
   returns nil   ; when file is not existed
   returns true  ; when file is downloaded
   returns false ; when file is downloading; attach with documentQuery
   */
  fileprivate func isFileDownloaded(fileURL: URL, documentQuery: inout NSMetadataQuery?) -> Bool? {
    if FileManager.default.fileExists(atPath: fileURL.path) {
      return true
    }

    do {
      let attributes = try fileURL.resourceValues(forKeys: [URLResourceKey.ubiquitousItemDownloadingStatusKey])

      guard let status = attributes.allValues[.ubiquitousItemDownloadingStatusKey] as? URLUbiquitousItemDownloadingStatus
        else { return nil }

      switch status {
      case URLUbiquitousItemDownloadingStatus.current, URLUbiquitousItemDownloadingStatus.downloaded:
        return true
      case URLUbiquitousItemDownloadingStatus.notDownloaded:
        try FileManager.default.startDownloadingUbiquitousItem(at: fileURL)

        documentQuery = NSMetadataQuery()
        guard let documentQuery = documentQuery else { return false }
        documentQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        documentQuery.valueListAttributes = [NSMetadataUbiquitousItemPercentDownloadedKey]
        documentQuery.predicate = NSPredicate(format: "%K > 0", argumentArray: [NSMetadataUbiquitousItemPercentDownloadedKey])
      default:
        ErrorReporting.report(message: "Unspecify status - \(status)")
      }
    } catch {
      ErrorReporting.report(error: error)
    }
    return false
  }

  fileprivate func setupUploadMetadataQuery() {
    fileDocumentUploadQuery = NSMetadataQuery()
    fileDocumentUploadQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
    fileDocumentUploadQuery.valueListAttributes = [NSMetadataUbiquitousItemPercentUploadedKey]
    fileDocumentUploadQuery.predicate = NSPredicate(format: "%K > 0", argumentArray: [NSMetadataUbiquitousItemPercentUploadedKey])

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(updateUploadedFiles),
      name: NSNotification.Name.NSMetadataQueryDidUpdate,
      object: fileDocumentUploadQuery
    )
    fileDocumentUploadQuery.start()
  }

  fileprivate func isFileUploaded(fileURL: URL) -> Bool? {
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }

    do {
      let attributes = try fileURL.resourceValues(forKeys: [URLResourceKey.ubiquitousItemIsUploadedKey])
      guard let isUploaded = attributes.allValues[.ubiquitousItemIsUploadedKey] as? Bool else { return nil }
      return isUploaded
    } catch {
      ErrorReporting.report(error: error)
    }
    return false
  }

  fileprivate func fileExists(fileURL: URL) -> Bool {
    if FileManager.default.fileExists(atPath: fileURL.path) { return true }

    do {
      let attributes = try fileURL.resourceValues(forKeys: [URLResourceKey.ubiquitousItemDownloadingStatusKey])
      return (attributes.allValues[URLResourceKey.ubiquitousItemDownloadingStatusKey] as? URLUbiquitousItemDownloadingStatus) != nil
    } catch {
      ErrorReporting.report(error: error)
    }
    return false
  }

  internal func getDataURL(_ containerURL: URL) -> URL {
    return containerURL.appendingPathComponent("data.plist")
  }
}
