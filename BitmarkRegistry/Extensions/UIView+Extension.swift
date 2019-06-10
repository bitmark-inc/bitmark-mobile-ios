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
      guard let color = newValue else {
        layer.borderColor = nil
        return
      }
      let underlinedLine = UIView()
      underlinedLine.backgroundColor = color
      addSubview(underlinedLine)
      underlinedLine.snp.makeConstraints { (make) in
        make.top.equalTo(self.snp.bottom).offset(5.0)
        make.leading.trailing.equalToSuperview()
        make.height.equalTo(1.0)
      }
      layer.borderColor = color.cgColor
    }
  }
}
