//
//  LoginViewController.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 6/24/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import SnapKit
import BitmarkSDK
import IQKeyboardManagerSwift
import RxSwift
import RxFlow
import RxCocoa

class LoginViewController: BaseRecoveryPhraseViewController, Stepper {
  var steps = PublishRelay<Step>()
  let disposeBag = DisposeBag()

  // MARK: - Properties
  fileprivate var _numericOrders: [Int]?
  private var numericOrders: [Int] {
    if _numericOrders == nil {
      _numericOrders = (0..<numberOfPhrases).map { extractNumericOrder($0) }
    }
    return _numericOrders!
  }
  override public var customFlowDirection: UICollectionView.ScrollDirection? { return .vertical }
  var submitButton: UIButton!
  var submitButtonBottomConstraint: Constraint!
  var currentCell: TestRecoveryPhraseLoginCell?
  var descriptionLabel: UILabel!
  var changePhraseOptionsButton: UIButton!
  // *** error result view ***
  let errorResultView = UIView()
  // *** custom input accessory view for testPhrase textfield ***
  var customInputAccessoryView: UIView!
  var autoCorrectStackView: UIStackView!
  var prevButton: UIButton!
  var nextButton: UIButton!
  let recoveryPhraseWords = RecoverPhrase.bip39ENWords
  let numberOfShowWord = 3
  var descriptionText: String {
    return String.localizedStringWithFormat("signin_writeRecoveryPhraseContentMessage".localized(tableName: "Phrase"), numberOfPhrases)
  }
  let changeTo24phrases = String.localizedStringWithFormat("signin_switchFormMessage".localized(tableName: "Phrase"), 24)
  let changeTo12phrases = String.localizedStringWithFormat("signin_switchFormMessage".localized(tableName: "Phrase"), 12)

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "signin_title".localized(tableName: "Phrase")
    setupViews()
    setupEvents()
  }

  // MARK: - Handlers
  @objc func changePhraseOptions(_ sender: UIButton) {
    if numberOfPhrases == 12 {
      changePhraseOptionsButton.setTitle(changeTo12phrases, for: .normal)
      numberOfPhrases = 24
    } else {
      changePhraseOptionsButton.setTitle(changeTo24phrases, for: .normal)
      numberOfPhrases = 12
    }
    descriptionLabel.text = descriptionText
    _numericOrders = nil
    clearForm()
    recoveryPhraseCollectionView.reloadData()
  }

  @objc func tapToSubmit(_ sender: UIButton) {
    do {
      let userInputPhrases = getUserInputPhrases()
      guard let seedVersion = SeedVersion(numberOfPhrases: userInputPhrases.count) else {
        throw("incorrect number of phrases")
      }

      UserSetting.shared.setAccountVersion(seedVersion)
      let account = try AccountService.getAccount(phrases: userInputPhrases)
      Global.currentAccount = account // track and store currentAccount
    } catch is RecoverPhrase.RecoverPhraseError {
      displayErrorView(isHidden: false)
      return
    } catch BitmarkSDK.SeedError.wrongNetwork {
      displayErrorView(isHidden: false)
      return
    } catch {
      showErrorAlert(message: "keychainStore".localized(tableName: "Error"))
      ErrorReporting.report(error: error)
      displayErrorView(isHidden: false)
      return
    }

    navigateNextOnboardingStepFromOnboardingStep(steps, disposeBag)
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
    displayErrorView(isHidden: true)
  }

  func editingTextfield(_ textfield: UITextField) {
    submitButton.isEnabled = validToSubmit()
    submitButton.backgroundColor = submitButton.isEnabled ? .mainBlueColor : .dustyGray
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

    if validToSubmit() {
      view.endEditing(true)
    } else {
      goNextCell()
    }
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
   customize to numeric number show as horizontal collection view; (but in fact the collection view is vertical collection view)
   */
  fileprivate func extractNumericOrder(_ rowIndex: Int) -> Int {
    return (rowIndex % 2 == 0) ? (rowIndex / 2 + 1) : (rowIndex + 1)/2 + (numberOfPhrases / 2)
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

  fileprivate func clearForm() {
    recoveryPhraseCollectionView.visibleCells.forEach { ($0 as? TestRecoveryPhraseLoginCell)?.clear() }
  }

  fileprivate func displayErrorView(isHidden: Bool) {
    errorResultView.isHidden = isHidden
    changePhraseOptionsButton.isHidden = !isHidden
  }
}

// MARK: - Setup Views/Events
extension LoginViewController {
  fileprivate func setupEvents() {
    recoveryPhraseCollectionView.register(cellWithClass: TestRecoveryPhraseLoginCell.self)
    recoveryPhraseCollectionView.dataSource = self
    recoveryPhraseCollectionView.delegate = self

    changePhraseOptionsButton.addTarget(self, action: #selector(changePhraseOptions), for: .touchUpInside)
    submitButton.addTarget(self, action: #selector(tapToSubmit), for: .touchUpInside)

    prevButton.addTarget(self, action: #selector(goPrevCell), for: .touchUpInside)
    nextButton.addTarget(self, action: #selector(goNextCell), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    descriptionLabel = CommonUI.descriptionLabel(text: descriptionText)
    descriptionLabel.lineHeightMultiple(1.2)

    let mainScrollView = UIScrollView()
    mainScrollView.addSubview(descriptionLabel)
    mainScrollView.addSubview(recoveryPhraseCollectionView)
    recoveryPhraseCollectionView.isScrollEnabled = false

    descriptionLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
          .inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }

    recoveryPhraseCollectionView.snp.makeConstraints { (make) in
      make.top.equalTo(descriptionLabel.snp.bottom).offset(35)
      make.width.equalToSuperview().offset(-40)
      make.leading.trailing.bottom.equalToSuperview()
          .inset(UIEdgeInsets(top: 0, left: 20, bottom: 25, right: 20))
    }

    // Setup Error Result View
    setupErrorResultView()
    errorResultView.isHidden = true

    submitButton = CommonUI.blueButton(title: "Submit".localized().localizedUppercase)
    submitButton.isEnabled = false
    submitButton.backgroundColor = .dustyGray

    changePhraseOptionsButton = UIButton(type: .system)
    changePhraseOptionsButton.setTitle(changeTo24phrases, for: .normal)
    changePhraseOptionsButton.titleLabel?.lineBreakMode = .byWordWrapping
    changePhraseOptionsButton.titleLabel?.lineHeightMultiple(1.2)
    changePhraseOptionsButton.titleLabel?.textAlignment = .center

    // *** Setup UI in view ***
    view.addSubview(mainScrollView)
    view.addSubview(changePhraseOptionsButton)
    view.addSubview(submitButton)
    view.addSubview(errorResultView)

    mainScrollView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 0, bottom: 25, right: 0))
    }

    changePhraseOptionsButton.snp.makeConstraints { (make) in
      make.top.equalTo(mainScrollView.snp.bottom)
      make.height.equalTo(120)
      make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      make.bottom.equalTo(submitButton.snp.top)
    }

    submitButton.snp.makeConstraints { (make) in
      make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      submitButtonBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
    }

    errorResultView.snp.makeConstraints { (make) in
      make.top.equalTo(mainScrollView.snp.bottom)
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }

    customInputAccessoryView = setupCustomInputAccessoryView()
  }

  fileprivate func setupErrorResultView() {
    let viewFont = UIFont(name: "Avenir", size: 15)
    let errorTitle = UILabel(text: "signin_resultWrong".localized(tableName: "Phrase"))
    errorTitle.font = viewFont?.bold
    errorTitle.textAlignment = .center
    errorTitle.textColor = .mainRedColor

    let message = UILabel(text: "signin_resultWrongMessage".localized(tableName: "Phrase"))
    message.font = viewFont
    message.numberOfLines = 0
    message.textAlignment = .center
    message.textColor = .mainRedColor

    let textView = UIView()
    textView.addSubview(errorTitle)
    textView.addSubview(message)

    errorTitle.snp.makeConstraints { (make) in
      make.top.equalToSuperview()
      make.leading.trailing.equalToSuperview()
    }

    message.snp.makeConstraints { (make) in
      make.top.equalTo(errorTitle.snp.bottom)
      make.leading.trailing.equalToSuperview()
    }

    errorResultView.addSubview(textView)

    textView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
          .inset(UIEdgeInsets(top: 25, left: 35, bottom: 50, right: 35))
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
