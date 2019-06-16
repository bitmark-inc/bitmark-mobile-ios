//
//  CustomTextField.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/12/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class DesignedTextField: UITextField {
  var bottomLineColor: UIColor = .mainBlueColor {
    didSet {
      bottomLine.backgroundColor = self.bottomLineColor
    }
  }
  var bottomLine: UIView!

  init(placeholder: String) {
    super.init(frame: CGRect.zero)
    self.placeholder = placeholder

    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // Change image of the clear button
  override func layoutSubviews() {
    super.layoutSubviews()

    for view in subviews {
      if let button = view as? UIButton {
        button.setImageForAllStates(UIImage(named: "blue-delete-label")!)
      }
    }
  }

  // MARK: - Handlers
  func onErrorStyle() {
    textColor = .mainRedColor
    bottomLine.backgroundColor = .mainRedColor
  }

  func offErrorStyle() {
    textColor = .black
    bottomLine.backgroundColor = bottomLineColor
  }

  // MARK: - Setup Views
  fileprivate func setupViews() {
    addPaddingLeft(10.0)
    font = UIFont(name: "Courier", size: 13)

    bottomLine = UIView()
    bottomLine.backgroundColor = bottomLineColor

    addSubview(bottomLine)

    bottomLine.snp.makeConstraints { (make) in
      make.leading.trailing.equalToSuperview()
      make.bottom.equalToSuperview().offset(9)
      make.height.equalTo(1)
    }
  }
}
