//
//  String.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/5/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

extension String {
  func middleShorten(eachMaxChars: Int = 4) -> String {
    return "\(self[0..<eachMaxChars])...\(self[count - eachMaxChars..<count])"
  }
}

extension String {
  subscript (bounds: CountableRange<Int>) -> Substring {
    let start = index(startIndex, offsetBy: bounds.lowerBound)
    let end = index(startIndex, offsetBy: bounds.upperBound)
    return self[start ..< end]
  }
}
