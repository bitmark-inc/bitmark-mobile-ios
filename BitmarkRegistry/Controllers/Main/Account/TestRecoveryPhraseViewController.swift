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
  private var recoveryPhrases = [String]()

  private let numberOfHiddenPhrases = 5
  private var hiddenPhraseIndexes = [Int]()
  private lazy var orderedHiddenPhraseIndexes: [Int] = {
    return hiddenPhraseIndexes.sorted()
  }()
  private var selectedHiddenPhraseBoxIndexPath: IndexPath!

  private let heightPerPhraseOptionItem: CGFloat = 25.0
  private let phraseOptionPadding: CGFloat = 15.0

  private var userPhraseChoice = [String?](repeating: nil, count: 12)
  
  let descriptionLabel: UILabel = {
    return CommonUI.descriptionLabel(text: "Tap the words to put them in the correct order for your recovery phrase:")
                   .lineHeightMultiple(1.2)

  }()

  lazy var phraseOptionCollectionView: UICollectionView = {
    let flowlayout = UICollectionViewFlowLayout()
    let collectionView = UICollectionView(frame: view.frame, collectionViewLayout: flowlayout)
    collectionView.backgroundColor = .clear
    return collectionView
  }()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "RECOVERY PHRASE"
    navigationItem.backBarButtonItem = UIBarButtonItem()
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

  // MARK: Data Handlers
  private func loadData() {
    loadRecoveryPhrases(&recoveryPhrases)
    hiddenPhraseIndexes = randomHiddenIndexes()
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
                          ? recoveryPhrases.count
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
  func reselectHiddenPhraseBoxCell(_ cell: TestRecoveryPhraseCell) {
    let indexPath = recoveryPhraseCollectionView.indexPath(for: cell)!
    orderedHiddenPhraseIndexes.append(indexPath.row)
    orderedHiddenPhraseIndexes.sort()

    userPhraseChoice[indexPath.row] = nil
    cell.matchingTestPhraseCell?.isHidden = false
    cell.showHiddenBox()
  }

  /*
   When user select phrase option:
   - 1. hiddens the phrase option cell itself
   - 2. matches phrase option into selected hidden recovery phrase box
   - 3. tracks user phrase choice
   - 4. selects next hidden recovery phrase box
   */
  func selectPhraseOptionCell(_ phraseOptionCell: TestPhraseOptionCell) {
    let selectedHiddenPhraseBoxCell = recoveryPhraseCollectionView.cellForItem(at: selectedHiddenPhraseBoxIndexPath) as! TestRecoveryPhraseCell

    phraseOptionCell.isHidden = true // 1
    let phraseOption = phraseOptionCell.phraseOptionBox.currentTitle!
    selectedHiddenPhraseBoxCell.setValueForHiddenBox(phraseOption, phraseOptionCell) // 2
    userPhraseChoice[selectedHiddenPhraseBoxIndexPath.row] = phraseOption // 3
    if let nextSelectedHiddenIndexPath = nextHiddenRecoveryPhraseIndexPath(selectedHiddenPhraseBoxIndexPath) { // 4
      recoveryPhraseCollectionView.selectItem(at: nextSelectedHiddenIndexPath, animated: false, scrollPosition: [])
      selectedHiddenPhraseBoxIndexPath = nextSelectedHiddenIndexPath
    }
  }
}

// MARK: - Setup Views
extension TestRecoveryPhraseViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let mainView = UIView()
    mainView.addSubview(descriptionLabel)
    mainView.addSubview(recoveryPhraseCollectionView)
    mainView.addSubview(phraseOptionCollectionView)

    descriptionLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    recoveryPhraseCollectionView.snp.makeConstraints { (make) in
      make.top.equalTo(descriptionLabel.snp.bottom).offset(25)
      make.leading.trailing.equalToSuperview()
    }

    phraseOptionCollectionView.snp.makeConstraints { (make) in
      make.top.equalTo(recoveryPhraseCollectionView.snp.bottom).offset(25)
      make.leading.trailing.bottom.equalToSuperview()
    }

    // *** Setup UI in view ***
    view.addSubview(mainView)

    mainView.snp.makeConstraints { (make) in
      make.top.equalTo(view.safeAreaLayoutGuide).offset(25)
      make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
      make.trailing.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
    }
  }
}

// MARK: - Support Functions
extension TestRecoveryPhraseViewController {
  func randomHiddenIndexes() -> [Int] {
    var randomIndexes = [Int]()
    var availableNums = Array(0..<recoveryPhrases.count)
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
    selectedHiddenPhraseBoxIndexPath = IndexPath(row: orderedHiddenPhraseIndexes.first!, section: 0)
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
}
