//
//  RecoveryPhraseViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class RecoveryPhraseViewController: BaseRecoveryPhraseCollectionViewController {

  // MARK: - Properties
  private let reuseIdentifier = "recoveryPhraseCell"
  private var recoveryPhrases = [String]()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()
    loadData()
  }

  // MARK: Data Handlers
  private func loadData() {
    loadRecoveryPhrases(&recoveryPhrases)
  }
}

// MARK: UICollectionViewDataSource
extension RecoveryPhraseViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return recoveryPhrases.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! RecoveryPhraseCell
    cell.setData(no: indexPath.row + 1, phrase: recoveryPhrases[indexPath.row])
    return cell
  }
}
