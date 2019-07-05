//
//  BaseRecoveryPhraseViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class BaseRecoveryPhraseViewController: UIViewController {

  // MARK: Properties
  private let sectionInsets = UIEdgeInsets(top: 5.0, left: 10.0, bottom: 0.0, right: 0.0)
  private let collectionViewPadding: CGFloat = 40.0
  private let heightPerRecoveryPhraseItem: CGFloat = 22.0
  private let screenHeightLimitationForRecoveryPhase: CGFloat = 600
  private var columns: CGFloat!
  let numberOfPhrases = 12

  lazy var recoveryPhraseCollectionView: UICollectionView = {
    let flowlayout = UICollectionViewFlowLayout()
    flowlayout.scrollDirection = .horizontal
    let collectionView = UICollectionView(frame: view.frame, collectionViewLayout: flowlayout)
    collectionView.backgroundColor = .clear
    return collectionView
  }()

  // MARK: - Data Handlers
  func loadRecoveryPhrases(_ phrases: inout [String]) {
    do {
      phrases = try Global.currentAccount!.getRecoverPhrase(language: .english)
    } catch {
      showErrorAlert(message: "Error happened while loading recovery phrase.")
      ErrorReporting.report(error: error)
    }
  }

  // MARK: - Layout Handlers
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // adjust number of columns: 2 columns for iphone 4'; other should be 1 column
    columns = view.frame.height > screenHeightLimitationForRecoveryPhase ? 1 : 2
    recoveryPhraseCollectionView.snp.makeConstraints { (make) in
      make.height.equalTo(CGFloat(numberOfPhrases) / columns * (heightPerRecoveryPhraseItem + sectionInsets.top))
    }
  }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension BaseRecoveryPhraseViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let paddingSpace = sectionInsets.left * (columns - 1) + collectionViewPadding
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / columns
    return CGSize(width: widthPerItem, height: heightPerRecoveryPhraseItem)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.top
  }
}
