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
  private let reuseIdentifier = "recoveryPhraseCell"
  private var recoveryPhrases = [String]()
  private let numberOfHiddenPhrases = 5
  private var hiddenPhraseIndexes = [Int]()

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
}

// MARK: UICollectionViewDataSource
extension TestRecoveryPhraseViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return recoveryPhrases.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! RecoveryPhraseCell
    let noIndex = indexPath.row + 1

    if hiddenPhraseIndexes.firstIndex(of: indexPath.row) != nil {
      cell.showHiddenBox(no: noIndex)
    } else {
      cell.setData(no: noIndex, phrase: recoveryPhrases[indexPath.row])
    }
    return cell
  }
}

// MARK: - Support Functins
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
}
