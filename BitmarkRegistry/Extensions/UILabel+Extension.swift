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
}
