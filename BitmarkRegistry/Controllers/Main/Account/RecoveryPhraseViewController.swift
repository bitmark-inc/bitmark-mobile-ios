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
  private let recoveryPhraseCollectionViewWidth: CGFloat = 370
  private let sectionInsets = UIEdgeInsets(top: 5.0, left: 50.0, bottom: 0.0, right: 0.0)
  private let columns: CGFloat = 1
  private let numberOfPhrases: CGFloat = 12
  private var recoveryPhrases = [String]()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()
    loadData()
  }

  // MARK: - Handlers

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
    let paddingSpace = sectionInsets.left * (columns - 1)
    let availableWidth = recoveryPhraseCollectionViewWidth - paddingSpace
    let widthPerItem = availableWidth / columns
    let heightPerItem = recoveryPhraseCollectionViewHeight.constant / numberOfPhrases
    return CGSize(width: widthPerItem, height: heightPerItem)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.top
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }
}


