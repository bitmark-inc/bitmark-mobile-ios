//
//  CustomUserDisplay.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 7/17/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

struct CustomUserDisplay {
  static func accountNumber(_ accountNumber: String?) -> String? {
    guard let accountNumber = accountNumber else { return nil }
    if let currentAccount = Global.currentAccount, currentAccount.getAccountNumber() == accountNumber {
      return "You".localized().localizedUppercase
    }

   return accountNumber.middleShorten()
  }

  static func datetime(_ dateAt: Date?) -> String? {
    guard let dateAt = dateAt else { return nil }
    return dateAt.string(withFormat: Constant.systemFullFormatDate).uppercased()
  }

  static func date(_ dateAt: Date?) -> String? {
    guard let dateAt = dateAt else { return nil }
    return dateAt.string(withFormat: "yyyy MMM dd").uppercased()
  }
}
