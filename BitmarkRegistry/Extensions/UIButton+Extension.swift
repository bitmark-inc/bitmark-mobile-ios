//
//  UIButton+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/3/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

// Declare a global var to produce a unique address as the assoc object handle
var disabledColorHandle: UInt8 = 0

extension UIButton {

  @IBInspectable
  var disabledBackgroundColor: UIColor? {
    get {
      return objc_getAssociatedObject(self, &disabledColorHandle) as? UIColor
    }
    set {
      if let color = newValue {
        self.setBackgroundColor(color, for: .disabled)
        objc_setAssociatedObject(self, &disabledColorHandle, color, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      } else {
        self.setBackgroundImage(nil, for: .disabled)
        objc_setAssociatedObject(self, &disabledColorHandle, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }
  }
}

// Reference: Create Background Image from Color:  https://spin.atomicobject.com/2018/04/25/uibutton-background-color/?fbclid=IwAR0tIN1uMyA8A7bcG_fdn5DL8mZElJ-0nKIi-L8HWvBBbED5eZ7rqQuN_qI
extension UIButton {
  private func image(withColor color: UIColor) -> UIImage? {
    let rect = CGRect(x: 0.0, y: 0.0, width: 2.0, height: 2.0)
    UIGraphicsBeginImageContext(rect.size)
    let context = UIGraphicsGetCurrentContext()

    let clipPath: CGPath = UIBezierPath(roundedRect: rect, cornerRadius: 0.2).cgPath

    context?.addPath(clipPath)
    context?.setFillColor(color.cgColor)
    context?.fillPath()

    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return image
  }

  func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
    self.setBackgroundImage(image(withColor: color), for: state)
  }
}
