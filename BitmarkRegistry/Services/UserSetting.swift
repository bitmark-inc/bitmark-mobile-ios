//
//  UserSetting.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/25/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class UserSetting {
  static let shared = UserSetting()
  private let authenticationKey = "authentication"
  private let accountVersionKey = "bitmark_account_version"

  func isUserLoggedIn() -> Bool {
    return UserDefaults.standard.object(forKey: authenticationKey) != nil
  }

  // *** Touch Face Id Setting ***
  func setTouchFaceIdSetting(isEnabled: Bool) {
    UserDefaults.standard.set(isEnabled, forKey: authenticationKey)
  }

  func getTouchFaceIdSetting() -> Bool {
    return UserDefaults.standard.bool(forKey: authenticationKey)
  }

  // *** Account Version ***
  func setAccountVersion(_ version: SeedVersion) {
    UserDefaults.standard.set(version.rawValue, forKey: accountVersionKey)
  }

  func getAccountVersion() -> SeedVersion? {
    let rawSeedVersion = UserDefaults.standard.integer(forKey: accountVersionKey)
    return SeedVersion(rawValue: rawSeedVersion)
  }
}
