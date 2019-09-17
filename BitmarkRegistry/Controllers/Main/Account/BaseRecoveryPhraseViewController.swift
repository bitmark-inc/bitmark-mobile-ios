//
//  BaseRecoveryPhraseViewController.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 6/11/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import SnapKit

class BaseRecoveryPhraseViewController: UIViewController {

  // MARK: Properties
  private let sectionInsets = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 0.0, right: 0.0)
  private let collectionViewPadding: CGFloat = 40.0
  private let heightPerRecoveryPhraseItem: CGFloat = 25.0
  var heightCollectionViewConstraint: Constraint?
  private let columns = 2
  public var customFlowDirection: UICollectionView.ScrollDirection? { return nil }
  public var numberOfPhrases = 12

  lazy var recoveryPhraseCollectionView: UICollectionView = {
    let flowlayout = UICollectionViewFlowLayout()
    flowlayout.scrollDirection = customFlowDirection ?? (columns == 1 ? .vertical : .horizontal)
    let collectionView = UICollectionView(frame: view.frame, collectionViewLayout: flowlayout)
    collectionView.backgroundColor = .clear
    return collectionView
  }()

  // MARK: - Data Handlers
  func loadRecoveryPhrases(_ phrases: inout [String]) {
    do {
      phrases = try Global.currentAccount!.getRecoverPhrase(language: .english)
      numberOfPhrases = phrases.count
    } catch {
      showErrorAlert(message: "loadRecoveryPhrase".localized(tableName: "Error"))
      ErrorReporting.report(error: error)
    }
  }

  // MARK: - Layout Handlers
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if heightCollectionViewConstraint == nil {
      recoveryPhraseCollectionView.snp.makeConstraints { (make) in
        heightCollectionViewConstraint = make.height.equalTo(0).constraint
      }
    }

    let collectionHeight = CGFloat(numberOfPhrases) / CGFloat(columns) * (heightPerRecoveryPhraseItem + sectionInsets.top)
    heightCollectionViewConstraint?.update(offset: collectionHeight)
  }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension BaseRecoveryPhraseViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let paddingSpace = sectionInsets.left * CGFloat(columns - 1) + collectionViewPadding
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / CGFloat(columns)
    return CGSize(width: widthPerItem, height: heightPerRecoveryPhraseItem)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.top
  }
}
