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

    guard let authRequest = createJWTRequestURL(for: account) else { return }
    URLSession.shared.dataTask(with: authRequest) { (data, response, error) in
      if let error = error {
        ErrorReporting.report(error: error)
        return
      }

      if let data = data {
        do {
          let jsonObject = try JSONSerialization.jsonObject(with: data) as! [String: String]
          Global.currentJwt = jsonObject["jwt_token"]
        } catch {
          ErrorReporting.report(error: error)
        }
      }
    }.resume()
  }

  fileprivate static func createJWTRequestURL(for account: Account) -> URLRequest? {
    do {
      let timestamp = Common.timestamp()
      let signature = try account.sign(message: timestamp.data(using: .utf8)!)

      let data: [String : Any] = [
        "requester" : account.getAccountNumber(),
        "timestamp" : timestamp,
        "signature" : signature.hexEncodedString
      ]
      let jsonData = try JSONSerialization.data(withJSONObject: data)

      let url = URL(string:  Global.ServerURL.mobile + "/api/auth")!
      var authRequest = URLRequest(url: url)
      authRequest.httpMethod = "POST"
      authRequest.allHTTPHeaderFields = [
        "Accept" : "application/json",
        "Content-Type": "application/json"
      ]
      authRequest.httpBody = jsonData
      return authRequest
    } catch {
      ErrorReporting.report(error: error)
      return nil
    }
  }
}
