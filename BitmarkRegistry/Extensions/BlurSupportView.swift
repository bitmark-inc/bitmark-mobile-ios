//
//  BlurSupportView.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/3/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class BlurSupportView: UIView {

  @IBInspectable
  var visibleAlpha: CGFloat = 0.5

  func visible() {
    alpha = visibleAlpha
    isHidden = false
  }
}
