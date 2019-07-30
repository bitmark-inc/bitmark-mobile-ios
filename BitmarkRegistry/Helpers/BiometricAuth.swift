//
//  BiometricAuth.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/21/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import LocalAuthentication

class BiometricAuth {
  let context = LAContext()

  func canEvaluatePolicy() -> Bool {
    return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
  }

  func authorizeAccess(handler: @escaping (String?) -> Void) {
    guard canEvaluatePolicy() else {
      handler("Face ID/Touch ID may not be configured")
      return
    }

    context.evaluatePolicy(LAPolicy.deviceOwnerAuthentication, localizedReason: "Your fingerprint signature is required.") { (isSuccess, evaluateError) in
      if isSuccess {
        handler(nil)
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
        handler(message)
      }
    }
  }
}
