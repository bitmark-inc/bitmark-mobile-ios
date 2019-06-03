//
//  MetaDataCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/2/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

protocol MetaDataCellDelegate {
  func gotoUpdateLabel(from cell: MetaDataCell)
  func changeEditMode(isEditMode: Bool)
  func adjustRelatedButtonsState()
  func removeCell(_ cell: MetaDataCell)
}

class MetaDataCell: UITableViewCell {

  // MARK: - Properties
  @IBOutlet weak var contentCellLeadingConstraint: NSLayoutConstraint!
  @IBOutlet weak var deleteView: UIView!
  @IBOutlet weak var descriptionTextField: DesignedTextField!
  @IBOutlet weak var labelTextField: DesignedTextField!

  var isValid: Bool = false
  var delegate: MetaDataCellDelegate?
  let deleteViewWidth: CGFloat = 30
  let labelContentSpace: CGFloat = 120
  let nextArrow: UIImageView = {
    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 11))
    imageView.image = UIImage(named: "Next-highlighted")
    return imageView
  }()

  override func awakeFromNib() {
    super.awakeFromNib()

    // Set up nextArrow icon
    labelTextField.rightViewMode = .always
    labelTextField.rightView = nextArrow
  }

  // style & reset state for all elements
  func styleCell(in view: UIView) {
    labelTextField.text = nil
    descriptionTextField.text = nil
  }

  // MARK: - Handlers
  @IBAction func tapToUpdateLabel(_ sender: UIButton) {
    endEditing(true)
    delegate?.gotoUpdateLabel(from: self)
  }

  func setLabel(_ label: String) {
    labelTextField.text = label
    labelTextField.sendActions(for: .editingChanged)
    labelTextField.sendActions(for: .editingDidEnd)
  }

  func getValues() -> (label: String, description: String) {
    return (labelTextField.text!, descriptionTextField.text!)
  }

  @IBAction func startEditingMetadata(_ sender: UITextField) {
    delegate?.changeEditMode(isEditMode: false)
  }

  @IBAction func changeTextField(_ sender: DesignedTextField) {
    isValid = labelTextField.text!.count > 0 && descriptionTextField.text!.count > 0
    setStyle(for: sender)
  }

  @IBAction func endEditingMetadata(_ sender: UITextField) {
    delegate?.adjustRelatedButtonsState()
  }

  @IBAction func tapToRemoveCell(_ sender: UIButton) {
    delegate?.removeCell(self)
  }

  func displayDeleteView(isShow: Bool) {
    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
      if !isShow { self.deleteView.isHidden = true }
      self.contentCellLeadingConstraint.constant = isShow ? self.deleteViewWidth : 0.0
      self.layoutIfNeeded()
    }, completion: { (_) in
      if isShow { self.deleteView.isHidden = false }
    })
  }

  func setDuplicatedStyle(isDuplicated: Bool) {
    labelTextField.borderLineColor = isDuplicated ? .mainRedColor : .mainBlueColor
  }

  private func setStyle(for textfield: DesignedTextField) {
    if isBeginningState() {
      labelTextField.borderLineColor = .mainBlueColor
      descriptionTextField.borderLineColor = .mainBlueColor
    } else {
      let isBlank = textfield.text! == ""
      if isBlank {
        textfield.borderLineColor = .mainRedColor // set error if current textfield is empty
      } else {
        textfield.borderLineColor = .mainBlueColor
        // set error for other textfield when current textfield's text is present and other is empty
        let otherTextfield = textfield == labelTextField ? descriptionTextField : labelTextField
        if otherTextfield?.text! == "" {
          otherTextfield?.borderLineColor = .mainRedColor
        }
      }
    }
  }

  private func isBeginningState() -> Bool {
    return labelTextField.text!.count == 0 && descriptionTextField.text!.count == 0
  }
}

extension MetaDataCell: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    delegate?.adjustRelatedButtonsState()
    return true
  }
}
