//
//  AccountService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class AccountService {

  static func createNewAccount(completion: @escaping (Account?, Error?) -> Void) throws  {
    let account = try Account()

    AccountKeyService.registerEncryptionPublicKey(account: account) {
      completion(account, $0)
    }
  }

  static func existsCurrentAccount() -> Bool {
    return getCurrentAccount() != nil
  }

  static func getCurrentAccount() -> Account? {
    var account: Account? = nil
    let seedCore = KeychainStore.getSeedDataFromKeychain()
    if let seedCore = seedCore {
      do {
        let seed = try Seed.fromCore(seedCore, version: .v2)
        account = try Account(seed: seed)
      } catch let e {
        Global.log.error(e)
        ErrorReporting.report(error: e)
      }
    }
    Global.currentAccount = account
    return account
  }

  // request jwt from mobile_server;
  // for now, just report error to developers; without bothering user
  static func requestJWT(account: Account) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
    defer {
      UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    var authRequest: URLRequest!
    do {
      let timestamp = Common.timestamp()
      let signature = try account.sign(message: timestamp.data(using: .utf8)!)

      let data: [String : Any] = [
        "requester" : account.getAccountNumber(),
        "timestamp" : timestamp,
        "signature" : signature.hexEncodedString
      ]
      let jsonData = try JSONSerialization.data(withJSONObject: data)

      let url = URL(string:  Global.mobileServerURL + "/api/auth")!
      authRequest = URLRequest(url: url)
      authRequest.httpMethod = "POST"
      authRequest.allHTTPHeaderFields = [
        "Accept" : "application/json",
        "Content-Type": "application/json"
      ]
      authRequest.httpBody = jsonData
    } catch {
      print(error)
    }

    URLSession.shared.dataTask(with: authRequest) { (data, response, error) in
      if let error = error {
        print(error)
        return
      }

      if let data = data {
        do {
          let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: String]
          if let jwtToken = jsonObject["jwt_token"] {
            try KeychainStore.saveToKeychain(jwt: jwtToken)
          }
        } catch {
          print(error)
        }
      }
    }.resume()
  }
}
