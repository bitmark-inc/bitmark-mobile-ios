//
//  AccountKeyService.swift
//  Bitmark
//
//  Created by Thuyen Truong on 6/29/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import RxSwift
import RxAlamofire
import RxOptional

class AccountKeyService {

  static let apiServerURL = Credential.valueForKey(keyName: Constant.InfoKey.apiServerURL)

  static func registerEncryptionPublicKey(account: Account, completion: @escaping (Error?) -> Void) {
    Global.log.info("registerEncryptionPublicKey - user(\(account.getAccountNumber())")

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

  static func getEncryptionPublicKey(accountNumber: String) -> Observable<Data> {
    Global.log.info("getEncryptionPublicKey - user(\(accountNumber)")

    let url = URL(string: Global.ServerURL.keyAccountAsset + "/" + accountNumber)!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = [
      "Accept": "application/json",
      "Content-Type": "application/json"
    ]

    return RxAlamofire.request(request)
      .debug()
      .responseData()
      .expectingObject(ofType: [String: String].self)
      .flatMap({ (data) -> Observable<Data?> in
        return Observable.just(data["encryption_pubkey"]?.hexDecodedData)
      })
      .errorOnNil()
  }
}
