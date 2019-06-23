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
}
