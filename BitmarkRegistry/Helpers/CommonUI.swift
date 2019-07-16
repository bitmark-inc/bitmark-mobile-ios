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

  static func actionMenuButton(title: String) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title.uppercased(), for: .normal)
    button.setTitleColor(.mainBlueColor, for: .normal)
    button.setTitleColor(.gray, for: .disabled)
    button.titleLabel?.font = UIFont(name: "Avenir-Black", size: 16)
    button.contentHorizontalAlignment = .right
    return button
  }

  static func fieldTitleLabel(text: String) -> UILabel {
    let label = UILabel(text: text.uppercased())
    label.font = UIFont(name: "Avenir", size: 14)
    label.numberOfLines = 0
    return label
  }

  static func inputFieldTitleLabel(text: String) -> UILabel {
    let label = UILabel(text: text.uppercased())
    label.font = UIFont(name: "Avenir-Black", size: 14)
    label.lineHeightMultiple(1.2)
    label.numberOfLines = 0
    return label
  }

  static func errorFieldLabel(text: String = "") -> UILabel {
    let label = UILabel(text: text.uppercased())
    label.font = UIFont(name: "Avenir", size: 14)
    label.lineHeightMultiple(1.2)
    label.textColor = .mainRedColor
    label.numberOfLines = 0
    return label
  }

  static func pageTitleLabel(text: String) -> UILabel {
    let label = UILabel(text: text.uppercased())
    label.font = UIFont(name: "Avenir-Black", size: 17)
    label.lineHeightMultiple(1.2)
    return label
  }

  static func descriptionLabel(text: String) -> UILabel {
    let label = UILabel(text: text)
    label.font = UIFont(name: "Avenir", size: 17)
    label.numberOfLines = 0
    return label
  }

  static func infoLabel(text: String = "") -> UILabel {
    let label = UILabel(text: text)
    label.font = UIFont(name: "Courier", size: 13)
    label.lineHeightMultiple(1.2)
    return label
  }

  static func alertMessageLabel(text: String) -> UILabel {
    let label = UILabel(text: text)
    label.numberOfLines = 0
    label.font = UIFont(name: "SF Pro Text", size: 16)
    label.textAlignment = .center
    return label
  }

  static func appActivityIndicator() -> UIActivityIndicatorView {
    let indicator = UIActivityIndicatorView()
    indicator.style = .whiteLarge
    indicator.color = .gray
    return indicator
  }

  static func disabledScreen() -> UIView {
    let view = UIView()
    view.backgroundColor = .black
    view.alpha = 0.7
    return view
  }
}
