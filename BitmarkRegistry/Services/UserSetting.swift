//
//  UserSetting.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/25/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

class UserSetting {
  static let shared = UserSetting()
  private let authenticationKey = "authentication"

  func setTouchFaceIdSetting(isEnabled: Bool) {
    UserDefaults.standard.set(isEnabled, forKey: authenticationKey)
  }

  func getTouchFaceIdSetting() -> Bool {
    return UserDefaults.standard.bool(forKey: authenticationKey)
  }
}
