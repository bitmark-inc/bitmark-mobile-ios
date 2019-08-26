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
    let prefixPart = self[safe: 0..<eachMaxChars]!
    let suffixPart = self[safe: count - eachMaxChars..<count]!
    return "[" + prefixPart + "..." + suffixPart + "]"
  }

  func embedInApp() -> String {
    return self + "?env=app"
  }
}

// MARK: - Localization
extension String {
  func localized(bundle: Bundle = .main, tableName: String = "Localizable") -> String {
    return NSLocalizedString(self, tableName: tableName, value: "**\(self)**", comment: "")
  }
}

// MARK: - StringProtocol
extension StringProtocol {
  func nsRange(from range: Range<Index>) -> NSRange {
    return .init(range, in: self)
  }
}
