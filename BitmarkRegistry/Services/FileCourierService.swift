//
//  FileCourierService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/3/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK
import Alamofire
import MobileCoreServices
import RxSwift
import RxAlamofire
import RxOptional

class FileCourierService {

  static func apiRequest(endpoint: String) -> Observable<URLRequest> {
    do {
      let url = URL(string: Global.ServerURL.fileCourier + endpoint)!
      var request = URLRequest(url: url)
      try request.attachAuth()
      return Observable.just(request)
    } catch {
      return Observable.error(error)
    }
  }

  static func uploadFile(assetId: String, encryptedFileURL: URL,
    sender: Account, senderSessionData: SessionData,
    receiverAccountNumber: String, receiverSessionData: SessionData) {

    guard let jwt = Global.currentJwt else { return }
    let assetFilename = encryptedFileURL.lastPathComponent

    do {
      let uploadURL = URL(string: Global.ServerURL.fileCourier + "/v2/files/" + assetId + "/" + sender.getAccountNumber())!

      let access = "\(receiverAccountNumber):\(receiverSessionData.encryptedKey.hexEncodedString)"
      let parameters: [String: String] = [
        "data_key_alg": senderSessionData.algorithm,
        "enc_data_key": senderSessionData.encryptedKey.hexEncodedString,
        "orig_content_type": "*",
        "access": access
      ]

      let headers = [
        "Authorization": "Bearer " + jwt
      ]

      let assetData = try Data(contentsOf: encryptedFileURL)

      Alamofire.upload(multipartFormData: { (multipartFormData) in
        for (key, value) in parameters {
          multipartFormData.append("\(value)".data(using: .utf8)!, withName: key)
        }

        let mineType = getMineType(of: encryptedFileURL)
        multipartFormData.append(assetData, withName: "file", fileName: assetFilename, mimeType: mineType)
      }, usingThreshold: UInt64(), to: uploadURL, method: .post, headers: headers, encodingCompletion: { (result) in
        switch result {
        case .success(let upload, _, _):
          upload.responseJSON { response in
          if let error = response.error {
            ErrorReporting.report(error: error)
          }
        }
        case .failure(let error):
          ErrorReporting.report(error: error)
        }
      })
    } catch {
      ErrorReporting.report(error: error)
    }
  }

  enum DownloadAssetError: Error {
    case invalidFormat
  }

  static func getDownloadableAssets(receiver: Account) -> Observable<[String]> {
    ErrorReporting.breadcrumbs(info: "getDownloadableAssets for receiver: \(receiver.getAccountNumber())", category: .FileCourier, traceLog: true)

    return Observable.just(receiver.getAccountNumber())
      .flatMap { apiRequest(endpoint: "/v2/files?receiver=" + $0) }
      .flatMap { (request) -> Observable<[String]> in
        RxAlamofire.request(request)
          .debug()
          .responseData()
          .expectingObject(ofType: [String : [String]].self)
          .map { $0["file_ids"] ?? [] }
          .flatMap({ (downloadableFileInfos) -> Observable<[String]> in
            for info in downloadableFileInfos {
              if !isValidDownloadableInfo(info) {
                let error = Global.appError(message: "Downloadable Info is in invalid format - \(downloadableFileInfos)")
                return Observable.error(error)
              }
            }

            return Observable.just(downloadableFileInfos)
          })
      }
  }

  typealias ResponseData = (sessionData: SessionData, filename: String, encryptedFileData: Data)
  static func downloadFile(assetId: String, receiver: Account, senderAccountNumber: String, senderPublicKey: Data) -> Observable<ResponseData> {
    ErrorReporting.breadcrumbs(info: "downloadFile", category: .FileCourier, traceLog: true)
    ErrorReporting.breadcrumbs(info: "assetId: \(assetId)", category: .FileCourier, traceLog: true)
    ErrorReporting.breadcrumbs(info: "receiver: \(receiver.getAccountNumber())", category: .FileCourier, traceLog: true)

    let endpoint = "/v2/files/" + assetId + "/" + senderAccountNumber + "?receiver=" + receiver.getAccountNumber()
    let request = apiRequest(endpoint: endpoint)
    return request.flatMap { (downloadRequest) -> Observable<ResponseData> in
      return Observable<ResponseData>.create({ (observer) -> Disposable in
        let task = URLSession.shared.downloadTask(with: downloadRequest) { (tempLocalURL, response, error) in
          if let error = error {
            observer.onError(error); return
          }

          do {
            guard let tempLocalURL = tempLocalURL, let httpResponse = response as? HTTPURLResponse else {
              throw "Can not parse response in download file: \(String(describing: response))"
            }

            guard let headers = httpResponse.allHeaderFields as? [String: String] else {
              throw "Header in download file API is incorrectly formatted: \(httpResponse.allHeaderFields)"
            }

            guard let filename = headers["File-Name"],
              let encryptedKey = headers["Enc-Data-Key"],
              let algorithm = headers["Data-Key-Alg"] else {
                throw "Header in download file response is incorrectly structured: \(headers)"
            }

            let sessionData = SessionData(encryptedKey: encryptedKey.hexDecodedData, algorithm: algorithm)
            let encryptedData = try Data(contentsOf: tempLocalURL)

            let responseData = (
              sessionData: sessionData,
              filename: filename,
              encryptedFileData: encryptedData
            )

            return observer.onNext(responseData)
          } catch {
            return observer.onError(error)
          }

        }
        task.resume()

        return Disposables.create {
          task.cancel()
        }
      })
    }
  }

  static func checkFileExistence(senderAccountNumber: AccountNumber, assetId: String) -> Observable<SessionData?> {
    ErrorReporting.breadcrumbs(info: "checkFileExistence", category: .FileCourier, traceLog: true)
    ErrorReporting.breadcrumbs(info: "assetId: \(assetId)", category: .FileCourier, traceLog: true)
    ErrorReporting.breadcrumbs(info: "senderAccountNumber: \(senderAccountNumber)", category: .FileCourier, traceLog: true)

    let request = apiRequest(endpoint: "/v2/files/" + assetId + "/" + senderAccountNumber)
    return request.flatMap { (checkFileExistenceRequest) -> Observable<SessionData?> in
      return Observable<SessionData?>.create({ (observer) -> Disposable in
        let task = URLSession.shared.dataTask(with: checkFileExistenceRequest) { (_, response, error) in
          if let error = error {
            ErrorReporting.report(error: error)
            observer.onNext(nil)
            return
          }

          guard let httpResponse = response as? HTTPURLResponse,
            let responseHeaders = httpResponse.allHeaderFields as? [String : String] else {
              let error = Global.appError(message: "Can not parse response in check File existence")
              ErrorReporting.report(error: error)
              observer.onNext(nil)
              return
          }

          guard httpResponse.statusCode == 200 else { observer.onNext(nil); return }

          guard let encryptedKey = responseHeaders["Enc-Data-Key"],
            let algorithm = responseHeaders["Data-Key-Alg"] else {
              let error = Global.appError(message: "Header in check file existence response is incorrectly structured: \(responseHeaders)")
              ErrorReporting.report(error: error)
              observer.onNext(nil)
              return
          }

          let sessionData = SessionData(encryptedKey: encryptedKey.hexDecodedData, algorithm: algorithm)
          observer.onNext(sessionData)
        }
        task.resume()

        return Disposables.create {
          task.cancel()
        }
      })
    }
  }

  static func updateAccessFile(assetId: String, sender: Account, receiverAccountNumber: String, receiverSessionData: SessionData) {
    guard let jwt = Global.currentJwt else { return }
    let updateAccessURL = URL(string: Global.ServerURL.fileCourier + "/v2/access/" + assetId + "/" + sender.getAccountNumber())!
    let access = "\(receiverAccountNumber):\(receiverSessionData.encryptedKey.hexEncodedString)"
    let params = ["access": access]
    let headers = ["Authorization": "Bearer " + jwt]

    let infoLog = "updateAccess in File for assetId: \(assetId); sender: \(sender.getAccountNumber()); receiver: \(receiverAccountNumber)"
    ErrorReporting.breadcrumbs(info: infoLog, category: .FileCourier, traceLog: true)

    Alamofire.request(updateAccessURL, method: .put, parameters: params, encoding: URLEncoding.default, headers: headers)
      .responseJSON { (response) in
        if response.result.isFailure {
          ErrorReporting.report(message: "Can not updateAccessFile")
        }
    }
  }

  static func deleteAccessFile(assetId: String, senderAccountNumber: String, receiverAccountNumber: String) {
    guard let jwt = Global.currentJwt else { return }
    let deleteAccessURL = URL(string: Global.ServerURL.fileCourier + "/v2/files/" + assetId + "/" + senderAccountNumber)!
    let params = ["receiver": receiverAccountNumber]
    let headers = ["Authorization": "Bearer " + jwt]

    let infoLog = "deleteAccess in File for assetId: \(assetId); sender: \(senderAccountNumber); receiver: \(receiverAccountNumber)"
    ErrorReporting.breadcrumbs(info: infoLog, category: .FileCourier, traceLog: true)

    Alamofire.request(deleteAccessURL, method: .delete, parameters: params, headers: headers)
      .responseJSON { (response) in
        if response.result.isFailure {
          ErrorReporting.report(message: "Can not deleteAccessFile")
        }
    }
  }

  static fileprivate func isValidDownloadableInfo(_ info: String) -> Bool {
    let regex = ".+/.+"
    return (info.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil)
  }

  static fileprivate func getMineType(of url: URL) -> String {
    let pathExtension: CFString = url.pathExtension as CFString
    guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)?.takeUnretainedValue(),
          let mineUTI = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType) else {
        ErrorReporting.report(message: "can not getMineType for pathExtension: \(pathExtension)")
        return "*"
    }
    return String(mineUTI.takeRetainedValue())
  }
}
