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
  var submitButton: SubmitButton!
  var submitButtonBottomConstraint: Constraint!
  var currentCell: TestRecoveryPhraseLoginCell?

  let errorResultView = UIView()
  var retryButton: UIButton!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "RECOVERY PHRASE SIGN-IN"
    navigationController?.isNavigationBarHidden = false
    setupViews()
    setupEvents()
  }

  // MARK: - Handlers
  @objc func tapToSubmit(_ sender: UIButton) {
    do {
      let account = try AccountService.getCurrentAccount(phrases: getUserInputPhrases())
      Global.currentAccount = account // track and store currentAccount
      try KeychainStore.saveToKeychain(account.seed.core)
    } catch RecoverPhrase.RecoverPhraseError.wordNotFound {
      errorResultView.isHidden = false
      return
    } catch {
      showErrorAlert(message: Constant.Error.keychainStore)
      return
    }

    // redirect to Main Screen
    gotoMainScreen()
  }

  // clear text in all textfields and hide errorResultView
  @objc func tapToRetry(_ sender: UIButton) {
    recoveryPhraseCollectionView.visibleCells.forEach { (cell) in
      (cell as! TestRecoveryPhraseLoginCell).clear()
    }
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
    cell.setData(numericOrder: indexPath.row + 1)
    return cell
  }
}

// MARK: - TestRecoverPhraseLoginDelegate
extension LoginViewController: TestRecoverPhraseLoginDelegate {
  func beginEditing(in cell: TestRecoveryPhraseLoginCell) {
    currentCell = cell
  }

  func editingTextfield() {
    submitButton.isEnabled = validToSubmit()
  }

  func finishEditing(in cell: TestRecoveryPhraseLoginCell) {
    let currentRow = recoveryPhraseCollectionView.indexPath(for: cell)!.row
    var nextRow = currentRow + 1
    if nextRow >= numberOfPhrases { nextRow = 0 }

    let nextCell = recoveryPhraseCollectionView.cellForItem(at: IndexPath(row: nextRow, section: 0)) as! TestRecoveryPhraseLoginCell
    nextCell.select()
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
    return (0..<numberOfPhrases).map { (row) -> String in
      let cell = recoveryPhraseCollectionView.cellForItem(at: IndexPath(row: row, section: 0)) as! TestRecoveryPhraseLoginCell
      return cell.testPhraseTextField.text!
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
