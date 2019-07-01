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

  static let apiServerURL = Credential.valueForKey(keyName: Constant.Key.apiServerURL)

  static func registerEncryptionPublicKey(account: Account, completion: @escaping (Error?) -> Void) {
    do {
      let encryptionPublicKey = account.encryptionKey.publicKey
      let signature = try account.sign(message: encryptionPublicKey)

      let data: [String : Any] = [
        "encryption_pubkey": encryptionPublicKey.hexEncodedString,
        "signature": signature.hexEncodedString
      ]
      let jsonData = try JSONSerialization.data(withJSONObject: data)

      let url = URL(string: apiServerURL + "/v1/encryption_keys/" + account.getAccountNumber())!
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.allHTTPHeaderFields = [
        "Accept" : "application/json",
        "Content-Type": "application/json",
      ]
      request.httpBody = jsonData

      URLSession.shared.dataTask(with: request) { (_, _, error) in
        completion(error)
      }.resume()
    } catch {
      completion(error)
    }
  }
}
