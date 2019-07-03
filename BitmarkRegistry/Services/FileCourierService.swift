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

class FileCourierServer {

  static func updateFileToCourierServer(
    assetId: String, encryptedFileURL: URL,
    sender: Account, senderSessionData: SessionData,
    receiverAccountNumber: String, receiverSessionData: SessionData) {

    guard let jwt = KeychainStore.getJwtFromKeychain() else { return }
    let assetFilename = encryptedFileURL.lastPathComponent

    do {
      let access = "\(receiverAccountNumber):\(receiverSessionData.encryptedKey.hexEncodedString)"
      let parameters: [String : String] = [
        "data_key_alg" : senderSessionData.algorithm,
        "enc_data_key" : senderSessionData.encryptedKey.hexEncodedString,
        "orig_content_type" : "*",
        "access" : access
      ]

      let uploadURL = URL(string: Global.fileCourierServerURL + "/v2/files/" + assetId + "/" + sender.getAccountNumber())!

      let headers = [
        "Authorization": "Bearer " + jwt
      ]

      let assetData = try Data(contentsOf: encryptedFileURL)

      Alamofire.upload(multipartFormData: { (multipartFormData) in
        for (key, value) in parameters {
          multipartFormData.append("\(value)".data(using: .utf8)!, withName: key)
        }

        multipartFormData.append(assetData, withName: "file", fileName: assetFilename, mimeType: "image/png")
      }, usingThreshold: UInt64(), to: uploadURL, method: .post, headers: headers) { (result) in
        switch result{
        case .success(let upload, _, _):
          upload.responseJSON { response in
            if let error = response.error {
              print(error)
              return
            }
          }
        case .failure(let error):
          print(error)
        }
      }
    } catch {
      print(error)
      return
    }
  }
}
