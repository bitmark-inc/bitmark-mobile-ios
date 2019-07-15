//
//  String+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/16/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

extension String {
  func middleShorten(eachMaxChars: Int = 4) -> String {
    if let currentAccount = Global.currentAccount, currentAccount.getAccountNumber() == self {
      return "YOU"
    }

    let prefixPart = self[safe: 0..<eachMaxChars]!
    let suffixPart = self[safe: count - eachMaxChars..<count]!
    return "[" + prefixPart + "..." + suffixPart + "]"
  }

  func embedInApp() -> String {
    return self + "?env=app"
  }
}
