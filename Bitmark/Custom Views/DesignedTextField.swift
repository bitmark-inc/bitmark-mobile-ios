//
//  CustomTextField.swift
//  Bitmark
//
//  Created by Thuyen Truong on 6/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

/**
 DesignedTextField:
 - **Bottom line color**: default is mainBlueColor
 - **Padding left**: 10px
 - **Error mode**: text & bottom line turn mainRedColor
 */
class DesignedTextField: UITextField {
  var bottomLineColor: UIColor = .mainBlueColor {
    didSet {
      bottomLine.backgroundColor = self.bottomLineColor
    }
  }
  var bottomLine: UIView!

  var setTextColor: UIColor = .black {
    didSet {
      textColor = self.setTextColor
    }
  }

  override var isEnabled: Bool {
    didSet {
      if self.isEnabled {
        textColor = setTextColor
        bottomLine.backgroundColor = bottomLineColor
        rightViewMode = .always
      } else {
        textColor = .silver
        bottomLine.backgroundColor = .wildSand
        rightViewMode = .never
      }
    }
  }

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
  func setStyle(state: FieldState) {
    switch state {
    case .default:
      bottomLine.backgroundColor = .silver
    case .error:
      setTextColor = .mainRedColor
      bottomLine.backgroundColor = .mainRedColor
    default:
      setTextColor = .black
      bottomLine.backgroundColor = bottomLineColor
    }
  }

  // MARK: - Setup Views
  fileprivate func setupViews() {
    addPaddingLeft(10.0)
    font = UIFont(name: Constant.andaleMono, size: 13)

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
