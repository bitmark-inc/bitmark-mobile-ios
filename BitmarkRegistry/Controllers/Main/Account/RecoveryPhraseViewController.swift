//
//  RecoveryPhraseViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class RecoveryPhraseViewController: UIViewController {

  // MARK: - Properties
  @IBOutlet weak var recoveryPhraseCollectionView: UICollectionView!
  @IBOutlet weak var recoveryPhraseCollectionViewHeight: NSLayoutConstraint!

  private let reuseIdentifier = "recoveryPhraseCell"
  private let sectionInsets = UIEdgeInsets(top: 5.0, left: 10.0, bottom: 0.0, right: 0.0)
  private let paddingCollectionView: CGFloat = 40.0
  private let heightPerRecoveryPhraseItem: CGFloat = 20.0
  private let screenHeightLimitationForRecoveryPhase: CGFloat = 600
  private var columns: CGFloat!
  private let numberOfPhrases: CGFloat = 12
  private var recoveryPhrases = [String]()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()
    loadData()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // adjust number of columns: 2 columns for iphone 4'; other should be 1 column
    columns = view.frame.height > screenHeightLimitationForRecoveryPhase ? 1 : 2
    recoveryPhraseCollectionViewHeight.constant = numberOfPhrases / columns * (heightPerRecoveryPhraseItem + sectionInsets.top)
  }

  // MARK: Load Data
  private func loadData() {
    do {
      recoveryPhrases = try Global.currentAccount!.getRecoverPhrase(language: .english)
    } catch let e {
      showInformedAlert(withTitle: "Error", message: e.localizedDescription)
    }
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

// MARK: UICollectionViewDelegateFlowLayout
extension RecoveryPhraseViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let paddingSpace = sectionInsets.left * (columns - 1) + paddingCollectionView
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / columns
    return CGSize(width: widthPerItem, height: heightPerRecoveryPhraseItem)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.top
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }
}


