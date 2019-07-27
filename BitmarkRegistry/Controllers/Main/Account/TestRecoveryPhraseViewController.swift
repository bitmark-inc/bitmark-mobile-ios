//
//  TestRecoveryPhraseViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class TestRecoveryPhraseViewController: BaseRecoveryPhraseViewController {

  // MARK: - Properties
  var recoveryPhraseSource: RecoveryPhraseSource!
  private var recoveryPhrases = [String]()

  // *** Properties for Hidden Phrase Function ***
  private let numberOfHiddenPhrases = 5
  private var hiddenPhraseIndexes = [Int]()
  private lazy var orderedHiddenPhraseIndexes: [Int] = {
    return hiddenPhraseIndexes.sorted()
  }()
  private var selectedHiddenPhraseBoxIndexPath: IndexPath!

  // *** Properties for Phrase Option Function ***
  private let heightPerPhraseOptionItem: CGFloat = 25.0
  private let phraseOptionPadding: CGFloat = 15.0
  private var userPhraseChoice: [String?]!

  lazy var phraseOptionCollectionView: UICollectionView = {
    let flowlayout = UICollectionViewFlowLayout()
    let collectionView = UICollectionView(frame: view.frame, collectionViewLayout: flowlayout)
    collectionView.backgroundColor = .clear
    return collectionView
  }()
  let successResultView = UIView()
  let errorResultView = UIView()
  var doneButton: UIButton!
  var retryButton: UIButton!
  var removeAccessButton: UIButton!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "TEST RECOVERY PHRASE"
    navigationItem.setHidesBackButton(true, animated: false)
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(doneHandler))
    setupViews()

    recoveryPhraseCollectionView.register(cellWithClass: TestRecoveryPhraseCell.self)
    recoveryPhraseCollectionView.delegate = self
    recoveryPhraseCollectionView.dataSource = self

    phraseOptionCollectionView.register(cellWithClass: TestPhraseOptionCell.self)
    phraseOptionCollectionView.delegate = self
    phraseOptionCollectionView.dataSource = self

    loadData()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // set default selected hidden cell for recoveryPhraseCollectionView
    setupDefaultSelectHiddenRecoveryPhraseBox()
  }

  // MARK: - Handlers
  @objc func clickRetryWhenError(_ sender: UIButton) {
    for hiddenIndex in hiddenPhraseIndexes {
      let indexPath = IndexPath(row: hiddenIndex, section: 0)
      recoveryPhraseCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
    }
    errorResultView.isHidden = true
    phraseOptionCollectionView.isHidden = false
    setupDefaultSelectHiddenRecoveryPhraseBox()
    setStyleForRecoveryPhraseCell()
  }

  @objc func doneHandler(_ sender: UIButton) {
    navigationController?.popToRootViewController(animated: true)
  }

  @objc func removeAccess(_ sender: UIButton) {
    do {
      AccountService.deregisterAPNS()
      try KeychainStore.removeSeedCoreFromKeychain()
      Global.clearData()
    } catch {
      showErrorAlert(message: Constant.Error.removeAccess)
    }
    guard let rootNavigationController = self.navigationController?
      .parent?
      .navigationController else {
        // Probably view hierarchy was changed
        showErrorAlert(message: Constant.Error.cannotNavigate)
        ErrorReporting.report(error: Constant.Error.cannotNavigate)
        return
    }

    let onboardingViewController = OnboardingViewController()
    rootNavigationController.setViewControllers([onboardingViewController],
                                                animated: true)
  }

  // MARK: Data Handlers
  private func loadData() {
    loadRecoveryPhrases(&recoveryPhrases)
    hiddenPhraseIndexes = randomHiddenIndexes()
    userPhraseChoice = [String?](repeating: nil, count: numberOfPhrases)
  }

  // MARK: - Override - UICollectionViewDelegateFlowLayout
  override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    if collectionView == recoveryPhraseCollectionView {
      return super.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
    } else {
      let cellText = phraseOptionIn(indexPath)
      let textSize = cellText.size(withAttributes: [NSAttributedString.Key.font: TestPhraseOptionCell.phraseOptionFont])
      return CGSize(width: textSize.width + phraseOptionPadding, height: heightPerPhraseOptionItem)
    }
  }
}

// MARK: - UICollectionViewDataSource
extension TestRecoveryPhraseViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return collectionView == recoveryPhraseCollectionView
                          ? numberOfPhrases
                          : numberOfHiddenPhrases
  }

  /*
   Set Cell Item For CollectionView
   1. recoveryPhraseCollectionView
   - show hidden box to random hidden phrase index
   - show data - recovery phrase for others
   2. phraseOptionCollectionView: show phrase options which index is in hidden phrase indexes
   */
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    switch collectionView {
    case recoveryPhraseCollectionView:
      let cell = collectionView.dequeueReusableCell(withClass: TestRecoveryPhraseCell.self, for: indexPath)
      let numericOrder = indexPath.row + 1
      if hiddenPhraseIndexes.firstIndex(of: indexPath.row) != nil {
        cell.setData(numericOrder: numericOrder)
        cell.showHiddenBox()
        cell.delegate = self
      } else {
        cell.setData(numericOrder: numericOrder, phrase: recoveryPhrases[indexPath.row])
      }
      return cell
    case phraseOptionCollectionView:
      let cell = collectionView.dequeueReusableCell(withClass: TestPhraseOptionCell.self, for: indexPath)
      cell.phraseOptionBox.setTitle(phraseOptionIn(indexPath), for: .normal)
      cell.delegate = self
      return cell
    default:
      fatalError()
    }
  }
}

// MARK: - UICollectionViewDelegate, SelectPhraseOptionDelegate
extension TestRecoveryPhraseViewController: SelectPhraseOptionDelegate, ReselectHiddenPhraseBoxDelegate {

  /*
   when user select cell: only impact when user select hidden cell in recoveryPhraseCollectionView,
   because in phraseOptionCollectionView, cell is coverred by UIButton -> it doesn't trigger the selection
   */
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard collectionView == recoveryPhraseCollectionView else { return }
    selectedHiddenPhraseBoxIndexPath = indexPath
  }

  // When user reselect test hidden recovery phrase box: revert the selection of phrase option
  // remove result display if it's showing
  func reselectHiddenPhraseBoxCell(_ cell: TestRecoveryPhraseCell) {
    let indexPath = recoveryPhraseCollectionView.indexPath(for: cell)!
    orderedHiddenPhraseIndexes.append(indexPath.row)
    orderedHiddenPhraseIndexes.sort()

    userPhraseChoice[indexPath.row] = nil
    cell.matchingTestPhraseCell?.isHidden = false
    cell.showHiddenBox()

    errorResultView.isHidden = true
    successResultView.isHidden = true
    phraseOptionCollectionView.isHidden = false
    setStyleForRecoveryPhraseCell()
  }

  /*
   When user select phrase option:
   - 1. hiddens the phrase option cell itself
   - 2. matches phrase option into selected hidden recovery phrase box
   - 3. tracks user phrase choice
   - 4. selects next hidden recovery phrase box
   - 5. if user finish to test recovery phrases, check the result
   */
  func selectPhraseOptionCell(_ phraseOptionCell: TestPhraseOptionCell) {
    guard let selectedHiddenPhraseBoxCell = recoveryPhraseCollectionView.cellForItem(at: selectedHiddenPhraseBoxIndexPath) as? TestRecoveryPhraseCell else { return }

    phraseOptionCell.isHidden = true // 1
    let phraseOption = phraseOptionCell.phraseOptionBox.currentTitle!
    selectedHiddenPhraseBoxCell.setValueForHiddenBox(phraseOption, phraseOptionCell) // 2
    userPhraseChoice[selectedHiddenPhraseBoxIndexPath.row] = phraseOption // 3
    if let nextSelectedHiddenIndexPath = nextHiddenRecoveryPhraseIndexPath(selectedHiddenPhraseBoxIndexPath) { // 4
      recoveryPhraseCollectionView.selectItem(at: nextSelectedHiddenIndexPath, animated: false, scrollPosition: [])
      selectedHiddenPhraseBoxIndexPath = nextSelectedHiddenIndexPath
    } else { // 5
      phraseOptionCollectionView.isHidden = true
      if isResultCorrect() {
        successResultView.isHidden = false
        setStyleForRecoveryPhraseCell(isSuccessResult: true)
      } else {
        errorResultView.isHidden = false
        setStyleForRecoveryPhraseCell(isSuccessResult: false)
      }
    }
  }
}

// MARK: - Setup Views/Events
extension TestRecoveryPhraseViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let descriptionLabel = CommonUI.descriptionLabel(text: "Tap the words to put them in the correct order for your recovery phrase:")
    descriptionLabel.lineHeightMultiple(1.2)

    let mainScrollView = UIScrollView()
    mainScrollView.addSubview(descriptionLabel)
    mainScrollView.addSubview(recoveryPhraseCollectionView)

    descriptionLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
          .inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }

    recoveryPhraseCollectionView.snp.makeConstraints { (make) in
      make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
      make.width.equalToSuperview().offset(-40)
      make.leading.trailing.bottom.equalToSuperview()
          .inset(UIEdgeInsets(top: 0, left: 20, bottom: 25, right: 20))
    }

    // *** Setup UI in view ***
    view.addSubview(mainScrollView)
    view.addSubview(phraseOptionCollectionView)

    mainScrollView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
        .inset(UIEdgeInsets(top: 25, left: 0, bottom: 25, right: 0))
    }

    phraseOptionCollectionView.snp.makeConstraints { (make) in
      make.top.equalTo(mainScrollView.snp.bottom).offset(25)
      make.height.equalTo(150)
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }

    setupSuccessResultView()
    setupErrorResultView()
    view.addSubview(successResultView)
    view.addSubview(errorResultView)
    successResultView.snp.makeConstraints { (make) in
      make.top.equalTo(mainScrollView.snp.bottom).offset(25)
      make.height.equalTo(150)
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }

    errorResultView.snp.makeConstraints { (make) in
      make.edges.equalTo(successResultView)
    }

    successResultView.isHidden = true
    errorResultView.isHidden = true
  }

  func setupSuccessResultView() {
    let viewFont = UIFont(name: "Avenir", size: 15)
    let successTitle = UILabel(text: "Success!")
    successTitle.font = viewFont?.bold
    successTitle.textAlignment = .center

    let message = UILabel(text: "Keep your written copy private in a secure and safe location.")
    message.font = viewFont
    message.numberOfLines = 0
    message.textAlignment = .center

    let textView = UIView()
    textView.addSubview(successTitle)
    textView.addSubview(message)

    successTitle.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    message.snp.makeConstraints { (make) in
      make.top.equalTo(successTitle.snp.bottom).offset(10)
      make.leading.trailing.equalToSuperview()
    }

    let successButton: UIButton!

    switch recoveryPhraseSource! {
    case .testRecoveryPhrase:
      doneButton = CommonUI.blueButton(title: "DONE")
      doneButton.addTarget(self, action: #selector(doneHandler), for: .touchUpInside)
      successButton = doneButton
    case .removeAccess:
      removeAccessButton = CommonUI.blueButton(title: "REMOVE ACCESS")
      removeAccessButton.addTarget(self, action: #selector(removeAccess), for: .touchUpInside)
      successButton = removeAccessButton
    }
    doneButton = CommonUI.blueButton(title: "DONE")

    successResultView.addSubview(textView)
    successResultView.addSubview(successButton)

    textView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
          .inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }

    successButton.snp.makeConstraints { (make) in
      make.leading.trailing.bottom.equalToSuperview()
    }
  }

  func setupErrorResultView() {
    let viewFont = UIFont(name: "Avenir", size: 15)
    let errorTitle = UILabel(text: "Error!")
    errorTitle.font = viewFont?.bold
    errorTitle.textAlignment = .center
    errorTitle.textColor = .mainRedColor

    let message = UILabel(text: "Please try again!")
    message.font = viewFont
    message.numberOfLines = 0
    message.textAlignment = .center
    message.textColor = .mainRedColor

    let textView = UIView()
    textView.addSubview(errorTitle)
    textView.addSubview(message)

    errorTitle.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    message.snp.makeConstraints { (make) in
      make.top.equalTo(errorTitle.snp.bottom).offset(10)
      make.leading.trailing.equalToSuperview()
    }

    retryButton = CommonUI.blueButton(title: "RETRY")
    retryButton.addTarget(self, action: #selector(clickRetryWhenError), for: .touchUpInside)

    errorResultView.addSubview(textView)
    errorResultView.addSubview(retryButton)

    textView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
          .inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }

    retryButton.snp.makeConstraints { (make) in
      make.leading.trailing.bottom.equalToSuperview()
    }
  }
}

// MARK: - Support Functions
extension TestRecoveryPhraseViewController {
  func randomHiddenIndexes() -> [Int] {
    var randomIndexes = [Int]()
    var availableNums = Array(0..<numberOfPhrases)
    for _ in 0..<numberOfHiddenPhrases {
      let randomIndex = availableNums.randomElement()!
      randomIndexes.append(randomIndex)
      availableNums.remove(at: availableNums.firstIndex(of: randomIndex)!)
    }
    return randomIndexes
  }

  func phraseOptionIn(_ indexPath: IndexPath) -> String {
    return recoveryPhrases[hiddenPhraseIndexes[indexPath.row]]
  }

  func setupDefaultSelectHiddenRecoveryPhraseBox() {
    guard let firstorderedHiddenPhraseIndex = orderedHiddenPhraseIndexes.first else { return }
    selectedHiddenPhraseBoxIndexPath = IndexPath(row: firstorderedHiddenPhraseIndex, section: 0)
    recoveryPhraseCollectionView.selectItem(at: selectedHiddenPhraseBoxIndexPath, animated: false, scrollPosition: [])
  }

  func nextHiddenRecoveryPhraseIndexPath(_ currentIndexPath: IndexPath) -> IndexPath? {
    if let orderedIndex = orderedHiddenPhraseIndexes.firstIndex(of: currentIndexPath.row) {
      orderedHiddenPhraseIndexes.remove(at: orderedIndex)
      if let nextIndex = orderedHiddenPhraseIndexes.first {
        return IndexPath(row: nextIndex, section: 0)
      }
    }
    return nil
  }

  func isResultCorrect() -> Bool {
    return hiddenPhraseIndexes.firstIndex(where: { recoveryPhrases[$0] != userPhraseChoice[$0] }) == nil
  }

  /*
   when result is error: set all cells into error styles
   when retry (isError is false): back to default style (reload style)
   */
  func setStyleForRecoveryPhraseCell(isSuccessResult: Bool? = nil) {
    for index in (0..<numberOfPhrases) {
      let indexPath = IndexPath(row: index, section: 0)
      guard let cell = recoveryPhraseCollectionView.cellForItem(at: indexPath) as? TestRecoveryPhraseCell else { return }
      if let isSuccessResult = isSuccessResult {
        cell.setStyle(isSuccess: isSuccessResult)
      } else {
        let isHiddenPhrase = hiddenPhraseIndexes.firstIndex(of: index) != nil
        cell.reloadStyle(isHiddenPhrase)
      }
    }
  }
}
