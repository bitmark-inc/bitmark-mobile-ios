//
//  String.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/5/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import CoreImage

extension String {
  func middleShorten(eachMaxChars: Int = 4, hasBracket: Bool = true) -> String {
    let shortString = "\(self[0..<eachMaxChars])...\(self[count - eachMaxChars..<count])"
    return hasBracket ? "[\(shortString)]" : shortString
  }

  func generateQRCode() -> UIImage? {
    let strData = data(using: .ascii)

    if let filter = CIFilter(name: "CIQRCodeGenerator") {
      filter.setValue(strData, forKey: "inputMessage")
      let transform = CGAffineTransform(scaleX: 3, y: 3)

      if let output = filter.outputImage?.transformed(by: transform) {
        return UIImage(ciImage: output)
      }
    }
    return nil
  }
}

extension String {
  subscript (bounds: CountableRange<Int>) -> Substring {
    let start = index(startIndex, offsetBy: bounds.lowerBound)
    let end = index(startIndex, offsetBy: bounds.upperBound)
    return self[start ..< end]
  }
}
