//
//  UIView+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/30/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

extension UIView {
  @IBInspectable
  var borderColor: UIColor? {
    set {
      layer.borderColor = newValue!.cgColor
    }
    get {
      if let color = layer.borderColor {
        return UIColor(cgColor: color)
      }
      return nil
    }
  }
}
