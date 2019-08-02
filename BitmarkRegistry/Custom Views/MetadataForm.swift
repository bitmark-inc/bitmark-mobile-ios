//
//  MetadataForm.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/12/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import SnapKit

protocol MetadataFormDelegate: class {
  func deleteMetadataForm(hasUUID uuid: String)
}

/**
 Create Metadata Form: supports in Create Property Screen
 - Components:
   - **Label**: textfield which has next-arrow to move to label selection screen.
   - **Description**: textfield for user to input description of the label.
   - **Delete button**: remove this metadata form from the parent view.
 */
class MetadataForm: UIView, UITextFieldDelegate {

  // MARK: - Properties
  let uuid: String
  var labelTextField: BoxTextField!
  var descriptionTextField: BoxTextField!
  var deleteView: UIView!
  let deleteViewWidth: CGFloat = 44
  var metadataFormLeadingConstraint: Constraint!
  var deleteButton: UIButton!
  let estimatedFormFrame = CGRect(x: 0, y: 0, width: 350, height: 100)
  var isDuplicated: Bool = false

  unowned var delegate: MetadataFormDelegate?
  var isValid: Bool {
    return !labelTextField.isEmpty && !descriptionTextField.isEmpty
  }
  var isOnDeleteMode: Bool = false {
    didSet {
      displayDeleteView(isHidden: !isOnDeleteMode)
    }
  }

  // MARK: - Init
  init(uuid: String) {
    self.uuid = uuid
    super.init(frame: estimatedFormFrame)

    setupViews()
    setupEvents()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Handlers
  func getValues() -> (label: String, description: String) {
    return (labelTextField.text!, descriptionTextField.text!)
  }

  func setLabel(_ label: String) {
    labelTextField.text = label
    labelTextField.sendActions(for: .editingDidBegin)
    labelTextField.sendActions(for: .editingChanged)
    labelTextField.sendActions(for: .editingDidEnd)
  }

  func setStyle(state: FieldState) {
    let color: UIColor!
    switch state {
    case .default:
      color = .silver
      labelTextField.text = nil
      descriptionTextField.text = nil
    case .success:
      color = .mainBlueColor
    case .error:
      color = .mainRedColor
    case .focus:
      color = .mainBlueColor
    }

    labelTextField.borderColor = color
    descriptionTextField.borderColor = color
  }

  // MARK: - Setup Views/Events
  fileprivate func setupEvents() {
    deleteButton.addAction(for: .touchUpInside) { [unowned self] in
      self.delegate?.deleteMetadataForm(hasUUID: self.uuid)
    }
  }

  func siblingTextField(_ tf: BoxTextField) -> BoxTextField {
    return tf == labelTextField ? descriptionTextField : labelTextField
  }

  func isBeginningState() -> Bool {
    return labelTextField.isEmpty && descriptionTextField.isEmpty
  }

  fileprivate func displayDeleteView(isHidden: Bool) {
    let offset = isHidden ? 0.0 : deleteViewWidth
    let alpha: CGFloat = isHidden ? 0.0 : 1.0
    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
      self.metadataFormLeadingConstraint.update(offset: offset)
      self.deleteView.alpha = alpha
      self.layoutIfNeeded()
    }, completion: { (_) in
    })
  }

  fileprivate func setupViews() {
    // *** Setup subviews ***
    labelTextField = BoxTextField(placeholder: "KEY")
    labelTextField.autocapitalizationType = .allCharacters
    labelTextField.returnKeyType = .done
    labelTextField.parentView = self

    descriptionTextField = BoxTextField(placeholder: "VALUE")
    descriptionTextField.returnKeyType = .done
    descriptionTextField.parentView = self

    let fieldStackView = UIStackView(arrangedSubviews: [labelTextField, descriptionTextField], axis: .vertical, spacing: -1)
    setupDeleteView()

    // *** Set up view ***
    addSubview(fieldStackView)
    addSubview(deleteView)

    deleteView.snp.makeConstraints { (make) in
      make.top.leading.bottom.equalToSuperview()
      make.width.equalTo(deleteViewWidth)
    }

    fieldStackView.snp.makeConstraints { (make) in
      make.top.trailing.bottom.equalToSuperview()
      metadataFormLeadingConstraint = make.leading.equalToSuperview().constraint
    }
  }

  fileprivate func setupDeleteView() {
    deleteButton = UIButton(imageName: "delete-label")
    deleteButton.contentMode = .scaleAspectFit

    deleteView = UIView()
    deleteView.alpha = 0
    deleteView.addSubview(deleteButton)

    deleteButton.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
    }
  }
}
