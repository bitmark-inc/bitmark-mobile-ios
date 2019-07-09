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
  func editingTextfield()
  func rollbackToBeginningCell()
}

class TestRecoveryPhraseLoginCell: UICollectionViewCell, UITextFieldDelegate {

  // MARK: - Properties
  var delegate: TestRecoverPhraseLoginDelegate?
  var numericOrderLabel: UILabel!
  var testPhraseTextField: UITextField!
  var autoCorrectScrollView: UIScrollView!
  var autoCorrectStackView: UIStackView!
  var nextButton: UIButton!

  // MARK: - Init
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
    setupEvents()

    var autoCorrectWords = RecoverPhrase.bip39ENWords
    autoCorrectWords.forEach { (word) in
      autoCorrectStackView.addArrangedSubview(autoCorrectWordButton(word))
    }
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
  }

  @objc func editingTextfield(_ textfield: UITextField) {
    testPhraseTextField.backgroundColor = testPhraseTextField.text!.isEmpty ? .wildSand : .white

    if let text = testPhraseTextField.text {
      setupAutoCorrectWords(text)
    }
  }

  @objc func endEditingTextfield(_ textfield: UITextField) {
    testPhraseTextField.borderWidth = 0
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if IQKeyboardManager.shared.canGoNext {
      self.nextButton.sendActions(for: .touchUpInside)
    } else {
      self.delegate?.rollbackToBeginningCell()
    }
    return true
  }

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

    testPhraseTextField = UITextField()
    testPhraseTextField.backgroundColor = .wildSand
    testPhraseTextField.textColor = .mainBlueColor
    testPhraseTextField.font = UIFont(name: "Avenir", size: 15)
    testPhraseTextField.borderColor = .mainBlueColor
    testPhraseTextField.returnKeyType = .done
    testPhraseTextField.autocapitalizationType = .none
    testPhraseTextField.autocorrectionType = .no
    testPhraseTextField.inputAccessoryView = setupCustomInputAccessoryView()

    // *** Setup UI in cell ***
    let mainView = UIView()
    mainView.addSubview(numericOrderCover)
    mainView.addSubview(testPhraseTextField)

    numericOrderCover.snp.makeConstraints { (make) in
      make.top.leading.bottom.equalToSuperview()
      make.width.equalTo(26)
    }

    testPhraseTextField.snp.makeConstraints { (make) in
      make.leading.equalTo(numericOrderCover.snp.trailing).offset(7)
      make.centerY.trailing.equalToSuperview()
      make.width.equalTo(120)
    }

    addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.centerX.centerY.top.equalToSuperview()
      make.width.greaterThanOrEqualTo(120)
    }
  }

  fileprivate func setupAutoCorrectWords(_ typingText: String) {
    autoCorrectStackView.arrangedSubviews.forEach { (autoCorrectWord) in
      if let autoCorrectWord = autoCorrectWord as? UIButton,
        let text = autoCorrectWord.title(for: .normal),
        !text.contains(typingText) {
        autoCorrectWord.isHidden = true
      }
    }
  }

  fileprivate func setupCustomInputAccessoryView() -> UIView {
    let prevButton = UIButton(type: .system, imageName: "IQButtonBarArrowUp")
    nextButton = UIButton(type: .system, imageName: "IQButtonBarArrowDown")
    let doneButton = UIButton(type: .system)
    doneButton.setTitle("Done", for: .normal)

    prevButton.addTarget(IQKeyboardManager.shared, action: #selector(IQKeyboardManager.goPrevious), for: .touchUpInside)
    nextButton.addTarget(IQKeyboardManager.shared, action: #selector(IQKeyboardManager.goNext), for: .touchUpInside)
    doneButton.addAction(for: .touchUpInside, {
      IQKeyboardManager.shared.resignFirstResponder()
    })

    let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 150, height: 25))
    scrollView.showsHorizontalScrollIndicator = false
    autoCorrectStackView = UIStackView(arrangedSubviews: [], axis: .horizontal, spacing: 10, alignment: .center, distribution: .fill)
    scrollView.addSubview(autoCorrectStackView)
    autoCorrectStackView.snp.makeConstraints({ (make) in
      make.edges.equalToSuperview()
    })

    let navButtonsGroup = UIStackView(arrangedSubviews: [prevButton, nextButton], axis:
      .horizontal, spacing: 3)
    let stackView = UIStackView(arrangedSubviews: [navButtonsGroup, scrollView, doneButton], axis: .horizontal, spacing: 20, alignment: .leading, distribution: .fill)

    navButtonsGroup.snp.makeConstraints({ (make) in
      make.centerY.equalToSuperview()
    })

    scrollView.snp.makeConstraints({ (make) in
      make.height.centerY.equalToSuperview()
    })

    let customView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
    customView.addSubview(stackView)

    stackView.snp.makeConstraints({ (make) in
      make.centerX.centerY.equalToSuperview()
      make.height.equalTo(30)
      make.leading.trailing.equalToSuperview()
        .inset(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
    })
    return customView
  }

  fileprivate func autoCorrectWordButton(_ word: String) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(word, for: .normal)

    button.addAction(for: .touchUpInside) {
      self.delegate?.currentCell?.testPhraseTextField.text = button.title(for: .normal)

      if IQKeyboardManager.shared.canGoNext {
        self.nextButton.sendActions(for: .touchUpInside)
      } else {
        self.delegate?.rollbackToBeginningCell()
      }
    }
    return button
  }
}
