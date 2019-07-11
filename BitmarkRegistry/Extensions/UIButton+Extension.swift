//
//  UIButton+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/9/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

extension UIButton {
  convenience init(type: ButtonType, imageName: String) {
    self.init(type: type)
    let buttonImage = UIImage(named: imageName)
    setImage(buttonImage, for: .normal)
    contentMode = .scaleAspectFit
  }
}
