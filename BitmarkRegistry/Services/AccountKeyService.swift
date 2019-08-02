//
//  AccountKeyService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class AccountKeyService {

  static let apiServerURL = Credential.valueForKey(keyName: Constant.InfoKey.apiServerURL)

  static func registerEncryptionPublicKey(account: Account, completion: @escaping (Error?) -> Void) {
    do {
      let encryptionPublicKey = account.encryptionKey.publicKey
      let signature = try account.sign(message: encryptionPublicKey)

      let data: [String: String] = [
        "encryption_pubkey": encryptionPublicKey.hexEncodedString,
        "signature": signature.hexEncodedString
      ]
      let jsonData = try JSONEncoder().encode(data)

      let url = URL(string: apiServerURL + "/v1/encryption_keys/" + account.getAccountNumber())!
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.allHTTPHeaderFields = [
        "Accept": "application/json",
        "Content-Type": "application/json"
      ]
      request.httpBody = jsonData

      URLSession.shared.dataTask(with: request) { (_, _, error) in
        completion(error)
      }.resume()
    } catch {
      completion(error)
    }
  }

  static func getEncryptionPublicKey(accountNumber: String, completion: @escaping (Data?, Error?) -> Void) {
    let url = URL(string: Global.ServerURL.keyAccountAsset + "/" + accountNumber)!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = [
      "Accept": "application/json",
      "Content-Type": "application/json"
    ]

    URLSession.shared.dataTask(with: request) { (data, _, error) in
      if let error = error {
        completion(nil, error)
        return
      }

      guard let data = data else { return }
      do {
        let jsonObject = try JSONDecoder().decode([String: String].self, from: data)
        let encryptionPubkey = jsonObject["encryption_pubkey"]?.hexDecodedData
        completion(encryptionPubkey, nil)
      } catch {
        completion(nil, error)
      }
    }.resume()
  }
}
