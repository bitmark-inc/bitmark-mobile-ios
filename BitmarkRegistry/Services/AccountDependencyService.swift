//
//  AccountInjection.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/12/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK
import RxSwift
import RxAlamofire
import RxOptional
import Alamofire
import Intercom

// Register Account with dependency services: JWT, Intercom, APNS
class AccountDependencyService {

  // MARK: - Properties
  static var _shared: AccountDependencyService?
  static var shared: AccountDependencyService {
    _shared = _shared ?? AccountDependencyService(account: Global.currentAccount!)
    return _shared!
  }

  let account: Account
  var registerAPNSSubject: PublishSubject<String>!
  fileprivate let disposeBag = DisposeBag()

  // MARK: - Init
  init(account: Account) {
    self.account = account
  }

  /**
   Request JWT, Intercom and APNS
   - When user finishes login/signup process (finish onboarding steps: setup touchId/Notification
   - When user enters the app from background
   */
  func requestJWTAndIntercomAndAPNSHandler() {
    registerAPNSSubject = PublishSubject<String>()
    Observable.zip(requestJWT(),
                   registerIntercom(),
                   registerAPNSSubject.asObservable())
      .flatMap { (_, intercomUserId, token) -> Observable<Void> in
        return self.registerAPNS(token: token, intercomUserId: intercomUserId)
      }
      .subscribeOn(SerialDispatchQueueScheduler(qos: .background))
      .subscribe(
        onError: { (error) in
          ErrorReporting.report(error: error)
          Global.log.error(error)
      }, onCompleted: {
        Global.log.info("Finish registering jwt, intercom and apns.")
      })
      .disposed(by: disposeBag)
  }

  // Remove APNS token from server
  func deregisterIntercomAndAPNS() {
    Intercom.logout()
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

extension AccountDependencyService {
  // request jwt from mobile_server;
  // for now, just report error to developers; without bothering user
  fileprivate func requestJWT() -> Observable<Void> {
    return createJWTRequestURL()
      .flatMap { (request) -> Observable<Void> in
        return RxAlamofire.requestJSON(request)
          .debug()
          .flatMap { (_, data) -> Observable<String?> in
            return Observable<String?>.of((data as? [String: String])?["jwt_token"])
          }
          .errorOnNil()
          .map { Global.currentJwt = $0 }
      }
  }

  fileprivate func createJWTRequestURL() -> Observable<URLRequest> {
    return Observable<URLRequest?>.create { (observer) -> Disposable in
      do {
        let timestamp = Common.timestamp()
        let signature = try self.account.sign(message: timestamp.data(using: .utf8)!)

        let data: [String: String] = [
          "requester": self.account.getAccountNumber(),
          "timestamp": timestamp,
          "signature": signature.hexEncodedString
        ]
        let jsonData = try JSONEncoder().encode(data)

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

  func registerIntercom() -> Observable<String> {
    Intercom.logout()
    let intercomUserId = account.getAccountNumber().intercomUserId()
    ErrorReporting.breadcrumbs(info: intercomUserId, category: "Intercom")
    Global.log.info("Registering user intercom with intercomUserId: \(intercomUserId)")

    return Observable.create { (observer) -> Disposable in
      Intercom.registerUser(withUserId: intercomUserId)
      observer.onNext(intercomUserId)
      observer.onCompleted()
      return Disposables.create()
    }
  }

  // Register push notification service with device token to server
  func registerAPNS(token: String, intercomUserId: String) -> Observable<Void> {
    ErrorReporting.breadcrumbs(info: token, category: "APNS")
    Global.log.info("Registering user notification with token: \(token)")

    return Observable<URLRequest>.create { (observer) -> Disposable in
      do {
        var request = try URLRequest(url: URL(string: "\(Global.ServerURL.mobile)/api/push_uuids")!, method: .post)
        try request.attachAuth()
        request.httpBody = try JSONEncoder().encode(["intercom_user_id": intercomUserId,
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
}

extension AccountNumber {
  func intercomUserId() -> String {
    return self.hexDecodedData.sha3(length: 256).hexEncodedString
  }
}
