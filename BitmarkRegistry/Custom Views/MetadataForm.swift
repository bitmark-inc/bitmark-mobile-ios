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
  func gotoUpdateLabel(from form: MetadataForm)
  func deleteMetadataForm(hasUUID uuid: String)
  func validateButtons(isValid: Bool)
  func changeMetadataViewMode(isOnEdit: Bool)
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
  var labelTextField: DesignedTextField!
  var labelTextFieldDeputy: UIButton!
  var descriptionTextField: DesignedTextField!
  var deleteView: UIView!
  let deleteViewWidth: CGFloat = 30
  var deleteButton: UIButton!
  var metadataFormLeadingConstraint: Constraint!
  let estimatedFormFrame = CGRect(x: 0, y: 0, width: 350, height: 100)

  weak var delegate: MetadataFormDelegate?
  var isValid: Bool = false
  var isOnDeleteMode: Bool = false {
    didSet {
      self.isOnDeleteMode ? showDeleteView() : hideDeleteView()
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

  func showDeleteView() {
    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
      self.metadataFormLeadingConstraint.update(offset: self.deleteViewWidth)
      self.layoutIfNeeded()
    }, completion: { (_) in
      self.deleteView.isHidden = false
    })
  }

  func hideDeleteView() {
    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
      self.deleteView.isHidden = true
      self.metadataFormLeadingConstraint.update(offset: 0.0)
      self.layoutIfNeeded()
    })
  }

  func setDuplicatedStyle(isDuplicated: Bool) {
    guard !labelTextField.isEmpty else { return }
    labelTextField.bottomLineColor = isDuplicated ? .mainRedColor : .mainBlueColor
  }

  @objc func beginEditingTextfield(_ textfield: DesignedTextField) {
    delegate?.changeMetadataViewMode(isOnEdit: false)
  }

  @objc func editingTextField(_ textfield: DesignedTextField) {
    isValid = !labelTextField.isEmpty && !descriptionTextField.isEmpty
    setStyle(for: textfield)
    delegate?.validateButtons(isValid: isValid)
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }

  // MARK: - Setup Views/Events
  fileprivate func setupEvents() {
    labelTextFieldDeputy.addAction(for: .touchUpInside) { [unowned self] in
      self.endEditing(true)
      self.delegate?.gotoUpdateLabel(from: self)
    }

    deleteButton.addAction(for: .touchUpInside) { [unowned self] in
      self.delegate?.deleteMetadataForm(hasUUID: self.uuid)
    }

    labelTextField.delegate = self
    descriptionTextField.delegate = self

    labelTextField.addTarget(self, action: #selector(beginEditingTextfield), for: .editingDidBegin)
    labelTextField.addTarget(self, action: #selector(editingTextField), for: .editingChanged)
    descriptionTextField.addTarget(self, action: #selector(beginEditingTextfield), for: .editingDidBegin)
    descriptionTextField.addTarget(self, action: #selector(editingTextField), for: .editingChanged)
  }

  fileprivate func setStyle(for textfield: DesignedTextField) {
    if isBeginningState() {
      labelTextField.bottomLineColor = .mainBlueColor
      descriptionTextField.bottomLineColor = .mainBlueColor
    } else {
      if textfield.isEmpty {
        textfield.onErrorStyle()
      } else {
        textfield.offErrorStyle()
        // set error for other textfield when current textfield's text is present and other is empty
        if let otherTextfield = textfield == labelTextField ? descriptionTextField : labelTextField, otherTextfield.isEmpty {
          otherTextfield.onErrorStyle()
        }
      }
    }
  }

  private func isBeginningState() -> Bool {
    return labelTextField.isEmpty && descriptionTextField.isEmpty
  }

  fileprivate func setupViews() {
    // *** Setup subviews ***
    let nextArrowImageView = UIImageView(image: UIImage(named: "Next-highlighted"))
    nextArrowImageView.contentMode = .scaleAspectFit

    let nextArrowView = UIView(frame: CGRect(x: 0, y: 0, width: nextArrowImageView.frame.width + 10, height: nextArrowImageView.frame.height))
    nextArrowView.addSubview(nextArrowImageView)
    nextArrowImageView.snp.makeConstraints { (make) in
      make.top.leading.bottom.equalToSuperview()
      make.trailing.equalToSuperview().offset(-10)
    }

    labelTextField = DesignedTextField(placeholder: "LABEL")
    labelTextField.rightViewMode = .always
    labelTextField.rightView = nextArrowView

    labelTextFieldDeputy = UIButton()

    let labelTextFieldCover = UIView()
    labelTextFieldCover.addSubview(labelTextField)
    labelTextFieldCover.addSubview(labelTextFieldDeputy)

    labelTextField.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }

    labelTextFieldDeputy.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalTo(labelTextField)
      make.height.equalTo(15)
    }

    descriptionTextField = DesignedTextField(placeholder: "DESCRIPTION")
    descriptionTextField.returnKeyType = .done

    let fieldStackView = UIStackView(arrangedSubviews: [labelTextFieldCover, descriptionTextField], axis: .vertical, spacing: 25)

    deleteButton = UIButton()
    deleteButton.setImage(UIImage(named: "delete_label"), for: .normal)
    deleteButton.contentMode = .scaleAspectFit

    deleteView = UIView()
    deleteView.isHidden = true
    deleteView.addSubview(deleteButton)
    deleteButton.snp.makeConstraints { (make) in
      make.leading.trailing.centerX.equalToSuperview()
      make.top.equalToSuperview().offset(3)
    }

    let spacingView = UIView()

    // *** Set up view ***
    addSubview(deleteView)
    addSubview(fieldStackView)
    addSubview(spacingView)

    deleteView.snp.makeConstraints { (make) in
      make.top.leading.bottom.equalToSuperview()
      make.width.equalTo(deleteViewWidth)
    }

    fieldStackView.snp.makeConstraints { (make) in
      make.top.trailing.equalToSuperview()
      metadataFormLeadingConstraint = make.leading.equalToSuperview().constraint
    }

    spacingView.snp.makeConstraints { (make) in
      make.top.equalTo(fieldStackView.snp.bottom)
      make.height.equalTo(25.0)
      make.leading.trailing.bottom.equalToSuperview()
    }
  }
}
