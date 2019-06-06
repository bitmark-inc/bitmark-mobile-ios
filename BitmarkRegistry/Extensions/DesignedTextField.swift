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

  @IBInspectable
  var deleteTextImage: UIImage? {
    didSet {
      guard let deleteTextImage = deleteTextImage else { return }
      rightView = deleteTextImageView(with: deleteTextImage)
    }
  }
}

extension DesignedTextField {
  private func deleteTextImageView(with image: UIImage) -> UIView {
    let deleteTextView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    let button = UIButton()
    button.setImage(image, for: .normal)

    // add delete image into deleteTextView
    deleteTextView.addSubview(button)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.leadingAnchor.constraint(equalTo: deleteTextView.leadingAnchor).isActive = true
    button.trailingAnchor.constraint(equalTo: deleteTextView.trailingAnchor).isActive = true
    button.topAnchor.constraint(equalTo: deleteTextView.topAnchor).isActive = true
    button.bottomAnchor.constraint(equalTo: deleteTextView.bottomAnchor).isActive = true

    button.addTarget(self, action: #selector(clickToDeleteTextField), for: .touchUpInside)
    return deleteTextView
  }

  @objc func clickToDeleteTextField(_ button: UIButton) {
    if let textfield = button.superview?.superview as? DesignedTextField {
      textfield.text = nil
      sendActions(for: .editingChanged)
      sendActions(for: .editingDidBegin)
    }
  }
}
