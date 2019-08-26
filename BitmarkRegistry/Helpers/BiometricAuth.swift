//
//  BiometricAuth.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/21/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import LocalAuthentication
import RxSwift

class BiometricAuth {
  let context = LAContext()

  func canEvaluatePolicy() -> Bool {
    return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
  }

  func authorizeAccess() -> Completable {
    return Completable.create(subscribe: { (completable) -> Disposable in
      let disposable = Disposables.create()

      guard self.canEvaluatePolicy() else {
        completable(.error(Global.appError(errorCode: 500, message: "Face ID/Touch ID may not be configured")))
        return disposable
      }

      self.context.evaluatePolicy(LAPolicy.deviceOwnerAuthentication, localizedReason: "YourAuthorizationIsRequired".localized()) { (isSuccess, evaluateError) in
        if isSuccess {
          completable(.completed)
        } else {
          let message: String
          switch evaluateError {
          case LAError.authenticationFailed?:
            message = "There was a problem verifying your identity."
          case LAError.userCancel?:
            message = "You pressed cancel Face ID/Touch ID authentication."
          case LAError.userFallback?:
            message = "You pressed password."
          case LAError.biometryNotAvailable?:
            message = "Face ID/Touch ID is not available."
          case LAError.biometryNotEnrolled?:
            message = "Face ID/Touch ID is not set up."
          case LAError.biometryLockout?:
            message = "Face ID/Touch ID is locked."
          default:
            message = "Face ID/Touch ID may not be configured"
          }
          completable(.error(Global.appError(errorCode: 500, message: message)))
        }
      }
      return disposable
    })
  }
}
