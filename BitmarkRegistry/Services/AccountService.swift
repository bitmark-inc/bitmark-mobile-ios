//
//  AccountService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK
import Alamofire
import RxAlamofire
import RxSwift
import RxOptional

class AccountService {

  static func createNewAccount(completion: @escaping (Account?, Error?) -> Void) throws {
    let account = try Account()

    AccountKeyService.registerEncryptionPublicKey(account: account) {
      completion(account, $0)
    }
  }

  static func existsCurrentAccount() -> Bool {
    return getCurrentAccount() != nil
  }

  static func getCurrentAccount() -> Account? {
    var account: Account?
    let seedCore = KeychainStore.getSeedDataFromKeychain()
    if let seedCore = seedCore {
      do {
        let seed = try Seed.fromCore(seedCore, version: .v2)
        account = try Account(seed: seed)
      } catch {
        ErrorReporting.report(error: error)
      }
    }
    Global.currentAccount = account
    return account
  }

  static func getAccount(phrases: [String]) throws -> Account {
    return try Account(recoverPhrase: phrases, language: .english)
  }

  // request jwt from mobile_server;
  // for now, just report error to developers; without bothering user
  static func requestJWT(account: Account) -> Observable<Void> {
    return createJWTRequestURL(for: account).flatMap { (request) -> Observable<Void> in
      return RxAlamofire.requestJSON(request)
        .debug()
        .flatMap { (_, data) -> Observable<String?> in
          return Observable<String?>.of((data as? [String: String])?["jwt_token"])
      }
      .errorOnNil()
      .map { Global.currentJwt = $0 }
    }
  }

  fileprivate static func createJWTRequestURL(for account: Account) -> Observable<URLRequest> {
    return Observable<URLRequest?>.create { (observer) -> Disposable in
      do {
        let timestamp = Common.timestamp()
        let signature = try account.sign(message: timestamp.data(using: .utf8)!)

        let data: [String: Any] = [
          "requester": account.getAccountNumber(),
          "timestamp": timestamp,
          "signature": signature.hexEncodedString
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: data)

        let url = URL(string: Global.ServerURL.mobile + "/api/auth")!
        var authRequest = URLRequest(url: url)
        authRequest.httpMethod = "POST"
        authRequest.allHTTPHeaderFields = [
          "Accept": "application/json",
          "Content-Type": "application/json"
        ]
        authRequest.httpBody = jsonData
        observer.onNext(authRequest)
      } catch let error {
        observer.onError(error)
      }
      observer.onCompleted()

      return Disposables.create()
    }.errorOnNil()
  }

  // Register push notification service with device token to server
  static func registerAPNS(token: String) -> Observable<Void> {
    ErrorReporting.breadcrumbs(info: token, category: "APNS")
    Global.log.info("Registering user notification with token: \(token)")

    return Observable<URLRequest>.create { (observer) -> Disposable in
      do {
        var request = try URLRequest(url: URL(string: "\(Global.ServerURL.mobile)/api/push_uuids")!, method: .post)
        try request.attachAuth()
        request.httpBody = try JSONEncoder().encode(["intercom_user_id": "",
                                                     "token": token,
                                                     "platform": "ios",
                                                     "client": "registry"])
        observer.onNext(request)
      } catch let error {
        observer.onError(error)
      }

      observer.onCompleted()
      return Disposables.create()
    }.flatMap { (request) -> Observable<Void> in
      return RxAlamofire.request(request)
        .debug()
        .map { _ in return }
    }
  }

  // Remove APNS token from server
  static func deregisterAPNS() {
    guard let token = Global.apnsToken else {
      Global.log.error("No APNS token")
      return
    }

    ErrorReporting.breadcrumbs(info: token, category: "APNS")
    Global.log.info("Registering user notification with token: \(token)")

    do {
      var request = try URLRequest(url: URL(string: "\(Global.ServerURL.mobile)/api/push_uuids/\(token)")!, method: .delete)
      try request.attachAuth()

      Alamofire.request(request).response { (result) in
        if let resp = result.response,
          resp.statusCode >= 300 {
          Global.log.error("Cannot deregister notification")
        }
      }
    } catch let error {
      ErrorReporting.report(error: error)
    }
  }
}
