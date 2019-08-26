//
//  UIView+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/10/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

extension UIView {

  @IBInspectable
  var underlinedLineColor: UIColor? {
    get {
      return layer.borderColor?.uiColor
    }
    set {
      guard let color = newValue else { layer.borderColor = nil; return }
      layer.borderColor = color.cgColor

      let underlinedLine = UIView()
      underlinedLine.backgroundColor = color

      addSubview(underlinedLine)
      underlinedLine.snp.makeConstraints { (make) in
        make.top.equalTo(snp.bottom).offset(0)
        make.leading.trailing.equalToSuperview()
        make.height.equalTo(1.0)
      }
    }
  }
}
