//
//  UserSetting.swift
//  Bitmark
//
//  Created by Thuyen Truong on 6/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
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

  func logUserOut() {
    UserDefaults.standard.removeObject(forKey: authenticationKey)
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
    UserDefaults.standard.set(version.stringFromVersion(), forKey: accountVersionKey)
  }

  func getAccountVersion() -> SeedVersion? {
    guard let versionString = UserDefaults.standard.string(forKey: accountVersionKey) else { return nil }
    return SeedVersion(versionString: versionString)
  }
}
