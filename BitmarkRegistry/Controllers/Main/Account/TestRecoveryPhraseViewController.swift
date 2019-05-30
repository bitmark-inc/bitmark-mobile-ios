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

  private let reuseIdentifier = "recoveryPhraseCell"
  private var recoveryPhrases = [String]()
  private let phraseOptionReuseIdentifier = "phraseOptionCell"
  private let phraseOptionPadding: CGFloat = 15.0
  private let numberOfHiddenPhrases = 5
  private var hiddenPhraseIndexes = [Int]()
  private lazy var orderedHiddenPhraseIndexes: [Int] = {
    return hiddenPhraseIndexes.sorted()
  }()
  private let heightPerPhraseOptionItem: CGFloat = 25.0


  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()
    loadData()
  }

  // MARK: Load Data
  private func loadData() {
    loadRecoveryPhrases(&recoveryPhrases)
    hiddenPhraseIndexes = randomHiddenIndexes()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // set default selected hidden cell for recoveryPhraseCollectionView
    let firstIndex = IndexPath(row: orderedHiddenPhraseIndexes.first!, section: 0)
    recoveryPhraseCollectionView.selectItem(at: firstIndex, animated: false, scrollPosition: [])
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
      - 3. selects next hidden recovery phrase box
      When user finish to test recovery phrase, check the result
   */
  func selectPhraseOptionCell(_ phraseOptionCell: PhraseOptionCell) {
    // Get selected hidden recovery phrase box
    let selectedIndexPath = recoveryPhraseCollectionView.indexPathsForSelectedItems!.first!
    let selectedRecoveryPhraseCell = (recoveryPhraseCollectionView.cellForItem(at: selectedIndexPath) as! RecoveryPhraseCell)

    let phraseOption = phraseOptionCell.phraseOptionBox.currentTitle!
    selectedRecoveryPhraseCell.setValueForHiddenBox(phraseOption, phraseOptionCell)
    if let nextSelectedHiddenIndexPath = nextHiddenRecoveryPhraseIndexPath(selectedIndexPath) {
      recoveryPhraseCollectionView.selectItem(at: nextSelectedHiddenIndexPath, animated: false, scrollPosition: [])
    } else {
      print("finish all")
    }
  }

   // When user reselect test hidden recovery phrase box: revert the selection of phrase option
  func reselectCell(_ cell: RecoveryPhraseCell) {
    let indexPath = recoveryPhraseCollectionView.indexPath(for: cell)!
    orderedHiddenPhraseIndexes.append(indexPath.row)
    orderedHiddenPhraseIndexes = orderedHiddenPhraseIndexes.sorted()

    cell.matchingTestPhraseCell?.isHidden = false
    cell.showHiddenBox(no: indexPath.row + 1)
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

  func nextHiddenRecoveryPhraseIndexPath(_ currentIndex: IndexPath) -> IndexPath? {
    if let orderedIndex = orderedHiddenPhraseIndexes.firstIndex(of: currentIndex.row) {
      orderedHiddenPhraseIndexes.remove(at: orderedIndex)
      if let nextIndex = orderedHiddenPhraseIndexes.first {
        return IndexPath(row: nextIndex, section: 0)
      }
    }
    return nil
  }
}
