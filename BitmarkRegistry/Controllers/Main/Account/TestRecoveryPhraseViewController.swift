//
//  TestRecoveryPhraseViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class TestRecoveryPhraseViewController: BaseRecoveryPhraseCollectionViewController {

  // MARK: - Properties
  @IBOutlet weak var phraseOptionCollectionView: UICollectionView!
  @IBOutlet weak var successResultView: UIView!
  @IBOutlet weak var errorResultView: UIView!
  @IBOutlet weak var resultBoxHeightConstraint: NSLayoutConstraint!

  private let reuseIdentifier = "recoveryPhraseCell"
  private var recoveryPhrases = [String]()
  private var selectedHiddenPhraseBoxIndexPath: IndexPath!
  private let phraseOptionReuseIdentifier = "phraseOptionCell"
  private let phraseOptionPadding: CGFloat = 15.0
  private let numberOfHiddenPhrases = 5
  private var userPhraseChoice = [String?](repeating: nil, count: 12)
  private var hiddenPhraseIndexes = [Int]()
  private lazy var orderedHiddenPhraseIndexes: [Int] = {
    return hiddenPhraseIndexes.sorted()
  }()
  private let heightPerPhraseOptionItem: CGFloat = 25.0
  private let resultBoxHeight: CGFloat = 130

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()
    loadData()
  }

  // MARK: Load Data
  private func loadData() {
    // avoid result box hide phraseOptionCollectionView in short height screen
    resultBoxHeightConstraint.constant = 0

    loadRecoveryPhrases(&recoveryPhrases)
    hiddenPhraseIndexes = randomHiddenIndexes()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // set default selected hidden cell for recoveryPhraseCollectionView
    setupDefaultSelectHiddenRecoveryPhraseBox()
  }

  // MARK: - UICollectionViewDelegateFlowLayout
  override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    if collectionView == recoveryPhraseCollectionView {
      return super.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
    } else {
      let cellText = phraseOptionIn(indexPath)
      let textSize = cellText.size(withAttributes: [NSAttributedString.Key.font: UIFont(name: "Avenir", size: 15)!])
      return CGSize(width: textSize.width + phraseOptionPadding, height: heightPerPhraseOptionItem)
    }
  }

  @IBAction func clickDoneWhenSuccess(_ sender: UIButton) {
    navigationController?.popToRootViewController(animated: true)
  }

  @IBAction func clickRetryWhenError(_ sender: UIButton) {
    for hiddenIndex in hiddenPhraseIndexes {
      let indexPath = IndexPath(row: hiddenIndex, section: 0)
      recoveryPhraseCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
    }
    errorResultView.isHidden = true
    phraseOptionCollectionView.isHidden = false
    setupDefaultSelectHiddenRecoveryPhraseBox()
    setStyleForRecoveryPhraseCell(isError: false)
    resultBoxHeightConstraint.constant = 0
  }
}

// MARK: UICollectionViewDataSource
extension TestRecoveryPhraseViewController: UICollectionViewDataSource, SelectPhraseOptionProtocol, ReselectHiddenPhraseBoxProtocol {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return collectionView == recoveryPhraseCollectionView ? recoveryPhrases.count : numberOfHiddenPhrases
  }

  /*
   Set Cell Item For CollectionView
   1. recoveryPhraseCollectionView
      - show hidden box to random hidden phrase index
      - show data - recovery phrase for others
   2. phraseOptionCollectionView: show phrase options which index is in hidden phrase indexes\
   */
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    switch collectionView {
    case recoveryPhraseCollectionView:
      let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! RecoveryPhraseCell)
      let noIndex = indexPath.row + 1

      if hiddenPhraseIndexes.firstIndex(of: indexPath.row) != nil {
        cell.showHiddenBox(no: noIndex)
        cell.delegate = self
      } else {
        cell.setData(no: noIndex, phrase: recoveryPhrases[indexPath.row])
      }
      return cell
    case phraseOptionCollectionView:
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: phraseOptionReuseIdentifier, for: indexPath) as! PhraseOptionCell
      cell.phraseOptionBox.setTitle(phraseOptionIn(indexPath), for: .normal)
      cell.delegate = self
      return cell
    default:
      fatalError()
    }
  }

  /*
   When user select phrase option:
      - 1. hiddens the phrase option (inside cell config)
      - 2. matches phrase option into selected hidden recovery phrase box
      - 3. tracks user phrase choice
      - 4. selects next hidden recovery phrase box
      - 5. if user finish to test recovery phrases, check the result
   */
  func selectPhraseOptionCell(_ phraseOptionCell: PhraseOptionCell) {
    let selectedHiddenPhraseBoxCell = recoveryPhraseCollectionView.cellForItem(at: selectedHiddenPhraseBoxIndexPath) as! RecoveryPhraseCell

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
      } else {
        errorResultView.isHidden = false
        setStyleForRecoveryPhraseCell(isError: true)
      }
      resultBoxHeightConstraint.constant = resultBoxHeight
    }
  }

   // When user reselect test hidden recovery phrase box: revert the selection of phrase option
  func reselectCell(_ cell: RecoveryPhraseCell) {
    let indexPath = recoveryPhraseCollectionView.indexPath(for: cell)!
    orderedHiddenPhraseIndexes.append(indexPath.row)
    orderedHiddenPhraseIndexes = orderedHiddenPhraseIndexes.sorted()

    userPhraseChoice[indexPath.row] = nil
    cell.matchingTestPhraseCell?.isHidden = false
    cell.showHiddenBox(no: indexPath.row + 1)
  }
}

extension TestRecoveryPhraseViewController {

  /*
   when user select cell: only logic when user select in recoveryPhraseCollectionView,
   because in phraseOptionCollectionView, cell is coverred by UIButton -> it doesn't trigger the selection
   */
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard collectionView == recoveryPhraseCollectionView else { return }
    selectedHiddenPhraseBoxIndexPath = indexPath
  }
}

// MARK: - Support Functions
extension TestRecoveryPhraseViewController {

  func phraseOptionIn(_ indexPath: IndexPath) -> String {
    return recoveryPhrases[hiddenPhraseIndexes[indexPath.row]]
  }

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

  func isResultCorrect() -> Bool {
    for hiddenIndex in hiddenPhraseIndexes {
      if recoveryPhrases[hiddenIndex] != userPhraseChoice[hiddenIndex] {
        return false
      }
    }
    return true
  }

  func setStyleForRecoveryPhraseCell(isError: Bool) {
    for index in (0..<numberOfPhrases) {
      let cell = recoveryPhraseCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) as! RecoveryPhraseCell
      if isError {
        cell.setErrorStyle()
      } else {
        let isPhraseHidden = hiddenPhraseIndexes.firstIndex(of: index) != nil
        cell.reloadStyle(isPhraseHidden)
      }
    }
  }
}
