//
//  CustomUserDisplay.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/17/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

struct CustomUserDisplay {
  static func accountNumber(_ accountNumber: String?) -> String? {
    guard let accountNumber = accountNumber else { return nil }
    if let currentAccount = Global.currentAccount, currentAccount.getAccountNumber() == accountNumber {
      return "YOU"
    }

   return accountNumber.middleShorten()
  }

  static func datetime(_ dateAt: Date?) -> String? {
    guard let dateAt = dateAt else { return nil }
    return dateAt.string(withFormat: Constant.systemFullFormatDate).uppercased()
  }
}
