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
  override public var customFlowDirection: UICollectionView.ScrollDirection? { return .vertical }
  var submitButton: SubmitButton!
  var submitButtonBottomConstraint: Constraint!
  var currentCell: TestRecoveryPhraseLoginCell?

  let errorResultView = UIView()
  var retryButton: UIButton!
  private lazy var numericOrders: [Int] = { (0..<numberOfPhrases).map { extractNumericOrder($0) } }()

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
    } catch is RecoverPhrase.RecoverPhraseError  {
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
    return cell
  }
}

// MARK: - TestRecoverPhraseLoginDelegate
extension LoginViewController: TestRecoverPhraseLoginDelegate {
  func editingTextfield() {
    submitButton.isEnabled = validToSubmit()
  }

  func goNextCell() {
    guard let currentCell = currentCell, let currentRow = recoveryPhraseCollectionView.indexPath(for: currentCell)?.row else { return }
    var nextNumericRow = extractNumericOrder(currentRow) + 1
    if nextNumericRow > numberOfPhrases { nextNumericRow = 1 }

    guard let nextRow = numericOrders.firstIndex(of: nextNumericRow) else { return }
    gotoCell(row: nextRow)
  }

  func goPrevCell() {
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
}

// MARK: - Validate Form
extension LoginViewController {

  // Submit button is enabled/valid when all textfields is filled text by user
  func validToSubmit() -> Bool {
    for cell in (recoveryPhraseCollectionView.visibleCells as! [TestRecoveryPhraseLoginCell]) {
      if cell.testPhraseTextField.isEmpty {
        return false
      }
    }
    return true
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
}

// MARK: - Setup Views/Events
extension LoginViewController {
  fileprivate func setupEvents() {
    recoveryPhraseCollectionView.register(cellWithClass: TestRecoveryPhraseLoginCell.self)
    recoveryPhraseCollectionView.dataSource = self
    recoveryPhraseCollectionView.delegate = self

    submitButton.addTarget(self, action: #selector(tapToSubmit), for: .touchUpInside)
    retryButton.addTarget(self, action: #selector(tapToRetry), for: .touchUpInside)
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
}
