//
//  BoxTextField.swift
//  Bitmark
//
//  Created by Thuyen Truong on 7/27/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

/**
 DesignedTextField:
 - **Bottom line color**: default is mainBlueColor
 - **Padding left**: 10px
 - **Error mode**: text & bottom line turn mainRedColor
 */
class BoxTextField: UITextField {
  var parentView: UIView?
  var setBorderColor: UIColor?
  let padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

  override var isEnabled: Bool {
    didSet {
      if self.isEnabled {
        textColor = .black
        borderColor = setBorderColor
        rightViewMode = .always
      } else {
        textColor = .silver
        borderColor = .wildSand
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
      borderColor = .silver
    case .focus:
      borderColor = .mainBlueColor
    case .success:
      borderColor = .mainBlueColor
    case .error:
      borderColor = .mainRedColor
    }
    setBorderColor = borderColor
  }

  // *** Padding for textfield ***
  override func textRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: padding)
  }

  override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: padding)
  }

  override func editingRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: padding)
  }

  // MARK: - Setup Views
  fileprivate func setupViews() {
    borderWidth = 1
    borderColor = .silver
    addPaddingLeft(10.0)

    font = UIFont(name: Constant.andaleMono, size: 13)
  }
}
