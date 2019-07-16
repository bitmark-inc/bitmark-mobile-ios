//
//  LoginViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/24/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import SnapKit
import BitmarkSDK

class LoginViewController: BaseRecoveryPhraseViewController {

  // MARK: - Properties
  private lazy var numericOrders: [Int] = { (0..<numberOfPhrases).map { extractNumericOrder($0) } }()
  override public var customFlowDirection: UICollectionView.ScrollDirection? { return .vertical }
  var submitButton: SubmitButton!
  var submitButtonBottomConstraint: Constraint!
  var currentCell: TestRecoveryPhraseLoginCell?
  // *** error result view ***
  let errorResultView = UIView()
  var retryButton: UIButton!
  // *** custom input accessory view for testPhrase textfield ***
  var customInputAccessoryView: UIView!
  var autoCorrectStackView: UIStackView!
  var prevButton: UIButton!
  var nextButton: UIButton!
  let recoveryPhraseWords = RecoverPhrase.bip39ENWords
  let numberOfShowWord = 3

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "RECOVERY PHRASE SIGN-IN"
    navigationController?.isNavigationBarHidden = false
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
    setupEvents()
  }

  // MARK: - Handlers
  @objc func tapToSubmit(_ sender: UIButton) {
    do {
      let account = try AccountService.getAccount(phrases: getUserInputPhrases())
      Global.currentAccount = account // track and store currentAccount
      try KeychainStore.saveToKeychain(account.seed.core)
    } catch is RecoverPhrase.RecoverPhraseError {
      errorResultView.isHidden = false
      return
    } catch BitmarkSDK.SeedError.wrongNetwork {
      errorResultView.isHidden = false
      return
    } catch {
      showErrorAlert(message: Constant.Error.keychainStore)
      ErrorReporting.report(error: error)
      errorResultView.isHidden = false
      return
    }

    let touchAuthenticationVC = TouchAuthenticationViewController()
    navigationController?.pushViewController(touchAuthenticationVC)
  }

  // clear text in all textfields and hide errorResultView
  @objc func tapToRetry(_ sender: UIButton) {
    recoveryPhraseCollectionView.visibleCells.forEach { ($0 as? TestRecoveryPhraseLoginCell)?.clear() }
    errorResultView.isHidden = true
  }
}

// MARK: - UICollectionViewDataSource
extension LoginViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return numberOfPhrases
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withClass: TestRecoveryPhraseLoginCell.self, for: indexPath)
    cell.delegate = self
    cell.setData(numericOrder: numericOrders[indexPath.row])
    cell.testPhraseTextField.inputAccessoryView = customInputAccessoryView
    return cell
  }
}

// MARK: - TestRecoverPhraseLoginDelegate - Custom input accessory view Handlers
extension LoginViewController: TestRecoverPhraseLoginDelegate {
  func beginEditingTextfield(_ textfield: UITextField) {
    filterAutoCorrectWords(textfield.text!)
    adjustReturnKeyType(for: textfield)
  }

  func editingTextfield(_ textfield: UITextField) {
    submitButton.isEnabled = validToSubmit()
    filterAutoCorrectWords(textfield.text!)
    adjustReturnKeyType(for: textfield)
  }

  @objc func goNextCell() {
    guard let currentCell = currentCell, let currentRow = recoveryPhraseCollectionView.indexPath(for: currentCell)?.row else { return }
    var nextNumericRow = extractNumericOrder(currentRow) + 1
    if nextNumericRow > numberOfPhrases { nextNumericRow = 1 }

    guard let nextRow = numericOrders.firstIndex(of: nextNumericRow) else { return }
    gotoCell(row: nextRow)
  }

  @objc func goPrevCell() {
    guard let currentCell = currentCell, let currentRow = recoveryPhraseCollectionView.indexPath(for: currentCell)?.row else { return }
    var prevNumericRow = extractNumericOrder(currentRow) - 1
    if prevNumericRow <= 0 { prevNumericRow = numberOfPhrases }

    guard let prevRow = numericOrders.firstIndex(of: prevNumericRow) else { return }
    gotoCell(row: prevRow)
  }

  fileprivate func gotoCell(row: Int) {
    if let _ = recoveryPhraseCollectionView.cellForItem(at: IndexPath(row: row, section: 0)) {
      view.endEditing(true)
    }
    guard let nextCell = recoveryPhraseCollectionView.cellForItem(at: IndexPath(row: row, section: 0)) as? TestRecoveryPhraseLoginCell else { return }
    nextCell.testPhraseTextField.becomeFirstResponder()
    nextCell.testPhraseTextField.sendActions(for: .editingDidBegin)
  }

  @objc func pickAutoCorrectWord(_ sender: UIButton) {
    currentCell?.testPhraseTextField.text = sender.title(for: .normal)
    goNextCell()
  }

  fileprivate func adjustReturnKeyType(for testPhraseTextField: UITextField) {
    testPhraseTextField.returnKeyType = validToSubmit() ? .done : .next
    testPhraseTextField.reloadInputViews()
  }
}

// MARK: - Validate Form
extension LoginViewController {

  // Submit button is enabled/valid when all textfields is filled text by user
  func validToSubmit() -> Bool {
    guard let visibleCells = recoveryPhraseCollectionView.visibleCells as? [TestRecoveryPhraseLoginCell] else { return false }
    return visibleCells.first(where: { $0.testPhraseTextField.isEmpty }) == nil
  }

  func getUserInputPhrases() -> [String] {
    return (1...numberOfPhrases).map { (numericOrder) -> String in
      if let row = numericOrders.firstIndex(of: numericOrder),
         let cell = recoveryPhraseCollectionView.cellForItem(at: IndexPath(row: row, section: 0)) as? TestRecoveryPhraseLoginCell {
        return cell.testPhraseTextField.text!
      }
      return ""
    }
  }
}

// MARK: - Support Functions
extension LoginViewController {

  /**
   Extract numeric number - prefix's cell.
   when columns is 1, simply [1...12]
   when columns is 2, customize to numeric number show as horizontal collection view; (but in fact the collection view is vertical collection view)
   */
  fileprivate func extractNumericOrder(_ rowIndex: Int) -> Int {
    if columns == 1 {
      return rowIndex + 1
    } else {
      return (rowIndex % 2 == 0) ? (rowIndex / 2 + 1) : (rowIndex + 1)/2 + (numberOfPhrases / 2)
    }
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

  fileprivate func filterAutoCorrectWords(_ typingText: String) {
    var filterWords = [String]()
    if !typingText.isEmpty {
      filterWords = recoveryPhraseWords.filter({ $0.hasPrefix(typingText) })
      if filterWords.count > numberOfShowWord { filterWords = Array(filterWords[0..<numberOfShowWord]) }
    }

    autoCorrectStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    filterWords.forEach { (word) in
      autoCorrectStackView.addArrangedSubview(autoCorrectWordButton(word))
    }
  }
}

// MARK: - Setup Views/Events
extension LoginViewController {
  fileprivate func setupEvents() {
    recoveryPhraseCollectionView.register(cellWithClass: TestRecoveryPhraseLoginCell.self)
    recoveryPhraseCollectionView.dataSource = self
    recoveryPhraseCollectionView.delegate = self

    submitButton.addTarget(self, action: #selector(tapToSubmit), for: .touchUpInside)
    retryButton.addTarget(self, action: #selector(tapToRetry), for: .touchUpInside)

    prevButton.addTarget(self, action: #selector(goPrevCell), for: .touchUpInside)
    nextButton.addTarget(self, action: #selector(goNextCell), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let descriptionLabel = CommonUI.descriptionLabel(text: "Please type all 12 words of your recovery phrase in the exact sequence below:")
    descriptionLabel.lineHeightMultiple(1.2)

    let mainView = UIView()
    mainView.addSubview(descriptionLabel)
    mainView.addSubview(recoveryPhraseCollectionView)

    descriptionLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    recoveryPhraseCollectionView.snp.makeConstraints { (make) in
      make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
      make.leading.trailing.equalToSuperview()
    }

    submitButton = SubmitButton(title: "SUBMIT")

    // *** Setup UI in view ***
    view.addSubview(mainView)
    view.addSubview(submitButton)

    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20))
    }

    submitButton.snp.makeConstraints { (make) in
      make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      submitButtonBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
    }

    // Setup Error Result View
    setupErrorResultView()
    errorResultView.isHidden = true
    view.addSubview(errorResultView)

    errorResultView.snp.makeConstraints { (make) in
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
      make.height.equalTo(120)
    }

    customInputAccessoryView = setupCustomInputAccessoryView()
  }

  fileprivate func setupErrorResultView() {
    let viewFont = UIFont(name: "Avenir", size: 15)
    let errorTitle = UILabel(text: "Wrong Recovery Phrase!")
    errorTitle.font = viewFont?.bold
    errorTitle.textAlignment = .center
    errorTitle.textColor = .mainRedColor

    let message = UILabel(text: "Please try again!")
    message.font = viewFont
    message.textAlignment = .center
    message.textColor = .mainRedColor

    let textView = UIView()
    textView.addSubview(errorTitle)
    textView.addSubview(message)

    errorTitle.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    message.snp.makeConstraints { (make) in
      make.top.equalTo(errorTitle.snp.bottom)
      make.leading.trailing.equalToSuperview()
    }

    retryButton = CommonUI.blueButton(title: "RETRY")

    errorResultView.addSubview(textView)
    errorResultView.addSubview(retryButton)

    textView.snp.makeConstraints { (make) in
      make.top.equalToSuperview()
      make.leading.equalToSuperview().offset(20)
      make.trailing.equalToSuperview().offset(-20)
    }

    retryButton.snp.makeConstraints { (make) in
      make.leading.trailing.bottom.equalToSuperview()
    }
  }

  fileprivate func setupCustomInputAccessoryView() -> UIView {
    prevButton = UIButton(type: .system, imageName: "IQButtonBarArrowUp")
    nextButton = UIButton(type: .system, imageName: "IQButtonBarArrowDown")

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
}
