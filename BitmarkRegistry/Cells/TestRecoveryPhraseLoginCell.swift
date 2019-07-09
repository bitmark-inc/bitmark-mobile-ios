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
  func validToSubmit() -> Bool
  func goNextCell()
  func goPrevCell()
}

class TestRecoveryPhraseLoginCell: UICollectionViewCell, UITextFieldDelegate {

  // MARK: - Properties
  var delegate: TestRecoverPhraseLoginDelegate?
  var numericOrderLabel: UILabel!
  var testPhraseTextField: UITextField!
  var autoCorrectStackView: UIStackView!
  let recoveryPhraseWords = RecoverPhrase.bip39ENWords
  let numberOfShowWord = 3

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
    adjustReturnKeyType()
  }

  @objc func editingTextfield(_ textfield: UITextField) {
    guard let typingText = testPhraseTextField.text else { return }
    adjustReturnKeyType()
    testPhraseTextField.backgroundColor = typingText.isEmpty ? .wildSand : .white
    filterAutoCorrectWords(typingText)
  }

  @objc func endEditingTextfield(_ textfield: UITextField) {
    testPhraseTextField.borderWidth = 0
    delegate?.editingTextfield()
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

// MARK: - Support Functions
extension TestRecoveryPhraseLoginCell {
  fileprivate func adjustReturnKeyType() {
    let validToSubmit = delegate?.validToSubmit() ?? false
    testPhraseTextField.returnKeyType = validToSubmit ? .done : .next
    testPhraseTextField.reloadInputViews()
  }

  fileprivate func filterAutoCorrectWords(_ typingText: String) {
    var filterWords = [String]()
    if !typingText.isEmpty {
      filterWords = recoveryPhraseWords.filter( { $0.hasPrefix(typingText) })
      if filterWords.count > numberOfShowWord { filterWords = Array(filterWords[0..<numberOfShowWord]) }
    }

    autoCorrectStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    filterWords.forEach { (word) in
      autoCorrectStackView.addArrangedSubview(autoCorrectWordButton(word))
    }
  }

  @objc func pickAutoCorrectWord(_ sender: UIButton) {
    delegate?.currentCell?.testPhraseTextField.text = sender.title(for: .normal)
    delegate?.goNextCell()
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

    testPhraseTextField = UITextField()
    testPhraseTextField.backgroundColor = .wildSand
    testPhraseTextField.textColor = .mainBlueColor
    testPhraseTextField.font = UIFont(name: "Avenir", size: 15)
    testPhraseTextField.borderColor = .mainBlueColor
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

  fileprivate func setupCustomInputAccessoryView() -> UIView {
    let prevButton = UIButton(type: .system, imageName: "IQButtonBarArrowUp")
    let nextButton = UIButton(type: .system, imageName: "IQButtonBarArrowDown")
    prevButton.addAction(for: .touchUpInside) { [weak self] in self?.delegate?.goPrevCell() }
    nextButton.addAction(for: .touchUpInside) { [weak self] in self?.delegate?.goNextCell() }

    autoCorrectStackView = UIStackView(arrangedSubviews: [], axis: .horizontal, spacing: 44, alignment: .center, distribution: .fill)
    let scrollView = UIScrollView()
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.addSubview(autoCorrectStackView)

    autoCorrectStackView.snp.makeConstraints({ (make) in
      make.edges.equalToSuperview()
    })

    let navButtonsGroup = UIStackView(arrangedSubviews: [prevButton, nextButton], axis: .horizontal, spacing: 20)
    let stackView = UIStackView(arrangedSubviews: [navButtonsGroup, scrollView], axis: .horizontal, spacing: 30)

    navButtonsGroup.snp.makeConstraints({ (make) in
      make.centerY.equalToSuperview()
    })

    scrollView.snp.makeConstraints({ (make) in
      make.height.centerY.equalToSuperview()
    })

    let customView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
    customView.addSubview(stackView)
    customView.backgroundColor = UIColor.wildSand

    stackView.snp.makeConstraints({ (make) in
      make.centerX.centerY.equalToSuperview()
      make.height.equalTo(30)
      make.leading.trailing.equalToSuperview()
          .inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    })

    return customView
  }

  fileprivate func autoCorrectWordButton(_ word: String) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(word, for: .normal)
    button.setTitleColor(.gray, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)

    button.snp.makeConstraints { (make) in
      make.height.equalTo(30)
    }

    button.addTarget(self, action: #selector(pickAutoCorrectWord), for: .touchUpInside)
    return button
  }
}
