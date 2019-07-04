//
//  UILabel+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

extension UILabel {
  func showIn(period: Double) {
    isHidden = false
    DispatchQueue.main.asyncAfter(deadline: .now() + period) { self.isHidden = true }
  }

  func lineHeightMultiple(_ lineHeightMultiple: CGFloat) {
    let attributedString = NSMutableAttributedString(string: text ?? "")
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineHeightMultiple = lineHeightMultiple

    // *** Apply attribute to string ***
    attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))

    // *** Set Attributed String to your label ***
    attributedText = attributedString
  }
}
