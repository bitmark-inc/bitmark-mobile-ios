//
//  UITextField+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/3/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class DesignedTextField: UITextField {

  let defaultBorderLineHeight: CGFloat = 1.0
  let defaultBorderLinePadding: CGFloat = 9.0

  @IBInspectable
  var leftPadding: CGFloat = 0.0 {
    didSet {
      leftView = UIView(frame: CGRect(x: 0, y: 0, width: leftPadding, height: frame.height))
      leftViewMode = .always
    }
  }

  @IBInspectable
  var borderLineColor: UIColor? {
    didSet {
      guard let borderLineColor = borderLineColor else { return }
      let bottomBorder = UIView()
      bottomBorder.backgroundColor = borderLineColor
      bottomBorder.translatesAutoresizingMaskIntoConstraints = false
      addSubview(bottomBorder)
      bottomBorder.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
      bottomBorder.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
      bottomBorder.topAnchor.constraint(equalTo: bottomAnchor, constant: defaultBorderLinePadding).isActive = true
      bottomBorder.heightAnchor.constraint(equalToConstant: defaultBorderLineHeight).isActive = true
    }
  }
}
