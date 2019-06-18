//
//  Common.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/10/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import SnapKit

class CommonUI {
  static func blueButton(title: String) -> UIButton {
    let button = UIButton(type: .system)
    button.backgroundColor = .mainBlueColor
    button.setTitle(title.uppercased(), for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.titleLabel?.font = UIFont(name: "Avenir-Black", size: 16)
    button.snp.makeConstraints { (make) in make.height.equalTo(45) }
    return button
  }

  static func lightButton(title: String) -> UIButton {
    let button = UIButton(type: .system)
    button.backgroundColor = .aliceBlue
    button.setTitle(title.uppercased(), for: .normal)
    button.setTitleColor(.mainBlueColor, for: .normal)
    button.titleLabel?.font = UIFont(name: "Avenir-Black", size: 16)
    button.snp.makeConstraints { (make) in make.height.equalTo(45) }
    return button
  }

  static func actionButton(title: String) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title.uppercased(), for: .normal)
    button.setTitleColor(.mainBlueColor, for: .normal)
    button.titleLabel?.font = UIFont(name: "Avenir-Black", size: 14)
    button.contentHorizontalAlignment = .left
    return button
  }

  static func fieldTitleLabel(text: String) -> UILabel {
    let label = UILabel(text: text.uppercased())
    label.font = UIFont(name: "Avenir", size: 14)
    label.numberOfLines = 0
    return label
  }

  static func descriptionLabel(text: String) -> UILabel {
    let label = UILabel(text: text)
    label.font = UIFont(name: "Avenir", size: 17)
    label.numberOfLines = 0
    return label
  }
}
