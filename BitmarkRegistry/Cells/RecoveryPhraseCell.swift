//
//  RecoveryPhraseCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/10/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class RecoveryPhraseCell: UICollectionViewCell {

  // MARK: - Properties
  let mainView = UIView()

  let numericOrderLabel: UILabel = {
    let label = UILabel()
    label.textColor = .alto
    label.font = UIFont(name: "Avenir", size: 15)
    return label
  }()

  let phraseLabel: UILabel = {
    let label = UILabel()
    label.textColor = .mainBlueColor
    label.font = UIFont(name: "Avenir", size: 15)
    return label
  }()

  // MARK: - Init
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setupViews()
  }

  // MARK: - Handlers
  func setData(numericOrder: Int, phrase: String) {
    numericOrderLabel.text = "\(numericOrder)."
    phraseLabel.text = phrase
  }

  // MARK: - Setup Views
  func setupViews() {

     // *** Setup subviews ***
    let numericOrderCover = UIView()
    numericOrderCover.addSubview(numericOrderLabel)
    numericOrderLabel.snp.makeConstraints { (make) in
      make.centerY.leading.trailing.height.equalToSuperview()
    }

    mainView.addSubview(numericOrderCover)
    mainView.addSubview(phraseLabel)

    numericOrderCover.snp.makeConstraints { (make) in
      make.top.leading.bottom.equalToSuperview()
      make.width.equalTo(26)
    }

    phraseLabel.snp.makeConstraints { (make) in
      make.leading.equalTo(numericOrderCover.snp.trailing).offset(7)
      make.centerY.trailing.equalToSuperview()
    }

    // *** Setup UI in view ***
    addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.centerX.centerY.top.equalToSuperview()
      make.width.greaterThanOrEqualTo(120)
    }
  }
}
