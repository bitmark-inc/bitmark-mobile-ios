//
//  UIButton+Extension.swift
//  Bitmark
//
//  Created by Thuyen Truong on 7/9/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

extension UIButton {
  convenience init(type: ButtonType? = nil, imageName: String) {
    if let type = type { self.init(type: type) } else { self.init() }

    let buttonImage = UIImage(named: imageName)
    setImage(buttonImage, for: .normal)
    contentMode = .scaleAspectFit
  }
}
