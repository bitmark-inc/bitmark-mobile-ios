//
//  TestRecoveryPhraseLoginCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/24/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK
import IQKeyboardManagerSwift

protocol TestRecoverPhraseLoginDelegate {
  var currentCell: TestRecoveryPhraseLoginCell? { get set }
  func beginEditingTextfield(_ textfield: UITextField)
  func editingTextfield(_ textfield: UITextField)
  func goNextCell()
}

class TestRecoveryPhraseLoginCell: UICollectionViewCell, UITextFieldDelegate {

  // MARK: - Properties
  var delegate: TestRecoverPhraseLoginDelegate?
  var numericOrderLabel: UILabel!
  var testPhraseTextField: UITextField!

  // MARK: - Init
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
    setupEvents()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Handlers
  func setData(numericOrder: Int) {
    numericOrderLabel.text = "\(numericOrder)."
  }

  func clear() {
    testPhraseTextField.clear()
    testPhraseTextField.sendActions(for: .editingChanged)
  }

  @objc func beginEditingTextfield(_ textfield: UITextField) {
    testPhraseTextField.borderWidth = 1
    delegate?.currentCell = self
    delegate?.beginEditingTextfield(textfield)
  }

  @objc func editingTextfield(_ textfield: UITextField) {
    guard let typingText = testPhraseTextField.text else { return }
    testPhraseTextField.backgroundColor = typingText.isEmpty ? .wildSand : .white
    delegate?.editingTextfield(textfield)
  }

  @objc func endEditingTextfield(_ textfield: UITextField) {
    testPhraseTextField.borderWidth = 0
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField.returnKeyType == .done {
      textField.resignFirstResponder()
    } else {
      delegate?.goNextCell()
    }
    return true
  }
}

// MARK: - Setup Views/Events
extension TestRecoveryPhraseLoginCell {
  fileprivate func setupEvents() {
    testPhraseTextField.delegate = self
    testPhraseTextField.addTarget(self, action: #selector(beginEditingTextfield), for: .editingDidBegin)
    testPhraseTextField.addTarget(self, action: #selector(editingTextfield), for: .editingChanged)
    testPhraseTextField.addTarget(self, action: #selector(endEditingTextfield), for: .editingDidEnd)
  }

  // MARK: - Setup Views
  fileprivate func setupViews() {
    // *** Setup subviews ***
    numericOrderLabel = UILabel()
    numericOrderLabel.textColor = .alto
    numericOrderLabel.font = UIFont(name: "Avenir", size: 15)

    let numericOrderCover = UIView()
    numericOrderCover.addSubview(numericOrderLabel)
    numericOrderLabel.snp.makeConstraints { (make) in
      make.centerY.leading.trailing.height.equalToSuperview()
    }

    testPhraseTextField = setupTestPhraseTextField()

    // *** Setup UI in cell ***
    let mainView = UIView()
    mainView.addSubview(numericOrderCover)
    mainView.addSubview(testPhraseTextField)

    numericOrderCover.snp.makeConstraints { (make) in
      make.top.leading.bottom.equalToSuperview()
      make.width.equalTo(23)
    }

    testPhraseTextField.snp.makeConstraints { (make) in
      make.leading.equalTo(numericOrderCover.snp.trailing).offset(7)
      make.centerY.trailing.equalToSuperview()
      make.width.equalTo(100)
    }

    addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.centerX.centerY.top.equalToSuperview()
      make.width.greaterThanOrEqualTo(120)
    }
  }

  fileprivate func setupTestPhraseTextField() -> UITextField {
    let testPhraseTextField = UITextField()
    testPhraseTextField.backgroundColor = .wildSand
    testPhraseTextField.textColor = .mainBlueColor
    testPhraseTextField.font = UIFont(name: "Avenir", size: 15)
    testPhraseTextField.borderColor = .mainBlueColor
    testPhraseTextField.autocapitalizationType = .none
    testPhraseTextField.autocorrectionType = .no
    return testPhraseTextField
  }
}
