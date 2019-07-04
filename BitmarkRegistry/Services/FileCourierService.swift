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

class FileCourierServer {

  static func updateFileToCourierServer(
    assetId: String, encryptedFileURL: URL,
    sender: Account, senderSessionData: SessionData,
    receiverAccountNumber: String, receiverSessionData: SessionData) {

    guard let jwt = KeychainStore.getJwtFromKeychain() else { return }
    let assetFilename = encryptedFileURL.lastPathComponent

    do {
      let uploadURL = URL(string: Global.ServerURL.fileCourier + "/v2/files/" + assetId + "/" + sender.getAccountNumber())!

      let access = "\(receiverAccountNumber):\(receiverSessionData.encryptedKey.hexEncodedString)"
      let parameters: [String : String] = [
        "data_key_alg" : senderSessionData.algorithm,
        "enc_data_key" : senderSessionData.encryptedKey.hexEncodedString,
        "orig_content_type" : "*",
        "access" : access
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
      }, usingThreshold: UInt64(), to: uploadURL, method: .post, headers: headers) { (result) in
        switch result{
        case .success(let upload, _, _):
          upload.responseJSON { response in
            if let error = response.error {
              ErrorReporting.report(error: error)
            }
          }
        case .failure(let error):
          ErrorReporting.report(error: error)
        }
      }
    } catch {
      ErrorReporting.report(error: error)
    }
  }

  static func getDownloadableAssets(receiver: Account, completion: @escaping (Array<String>?, Error?) -> Void) {
    guard let jwt = KeychainStore.getJwtFromKeychain() else { return }

    let url = URL(string: Global.ServerURL.fileCourier + "/v2/files?receiver=" + receiver.getAccountNumber())!
    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = [
      "Accept" : "application/json",
      "Content-Type" : "application/json",
      "Authorization" : "Bearer " + jwt
    ]

    URLSession.shared.dataTask(with: request) { (data, response, error) in
      if let error = error {
        completion(nil, error); return
      }

      if let data = data {
        do {
          let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String : Array<String>]
          let downloadableFileInfos = jsonObject["file_ids"]

          // validate file_ids response
          downloadableFileInfos?.forEach({ (info) in
            if !isValidDownloadableInfo(info) {
              completion(nil, nil)
            }
          })

          completion(downloadableFileInfos, nil)
        } catch {
          completion(nil, error)
        }
      }
    }.resume()
  }

  typealias responseData = (sessionData: SessionData, filename: String, encryptedFileData: Data)
  static func downloadFileFromCourierServer(
    assetId: String, receiver: Account,
    senderAccountNumber: String, senderPublicKey: Data,
    completion: @escaping (responseData?, Error?) -> Void) {

    guard let jwt = KeychainStore.getJwtFromKeychain() else { return }

    let downloadURL = URL(string: Global.ServerURL.fileCourier + "/v2/files/" + assetId + "/" + senderAccountNumber + "?receiver=" + receiver.getAccountNumber())!
    var downloadRequest = URLRequest(url: downloadURL)
    downloadRequest.allHTTPHeaderFields = [
      "Authorization": "Bearer " + jwt
    ]

    URLSession.shared.downloadTask(with: downloadRequest) { (tempLocalURL, response, error) in
      if let error = error {
        completion(nil, error); return
      }

      guard let tempLocalURL = tempLocalURL,
            let httpResponse = response as? HTTPURLResponse else {
        let error = Global.appError(errorCode: 500, message: "Can not parse response in download file")
        completion(nil, error)
        return
      }

      do {
        let headers = httpResponse.allHeaderFields as! [String: String]
        if let filename = headers["File-Name"],
           let encryptedKey = headers["Enc-Data-Key"],
           let algorithm = headers["Data-Key-Alg"] {

          let sessionData = SessionData(encryptedKey: encryptedKey.hexDecodedData, algorithm: algorithm)
          let encryptedData = try Data(contentsOf: tempLocalURL)

          let responseData = (
            sessionData: sessionData,
            filename: filename,
            encryptedFileData: encryptedData
          )

          completion(responseData, nil)
        } else {
          let error = Global.appError(errorCode: 500, message: "header in download file response is formatted incorrectly")
          completion(nil, error)
        }

      } catch {
        completion(nil, error)
      }
    }.resume()
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

