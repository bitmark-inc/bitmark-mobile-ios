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
  var numericOrderLabel: UILabel!
  var phraseLabel: UILabel!

  // MARK: - Init
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Handlers
  func setData(numericOrder: Int, phrase: String) {
    numericOrderLabel.text = "\(numericOrder)."
    phraseLabel.text = phrase
    isUserInteractionEnabled = false
  }

  // MARK: - Setup Views
  func setupViews() {
    // *** Setup subviews ***
    numericOrderLabel = UILabel()
    numericOrderLabel.textColor = .alto
    numericOrderLabel.font = UIFont(name: "Avenir", size: 15)

    let numericOrderCover = UIView()
    numericOrderCover.addSubview(numericOrderLabel)
    numericOrderLabel.snp.makeConstraints { (make) in
      make.centerY.leading.trailing.height.equalToSuperview()
    }

    phraseLabel = UILabel()
    phraseLabel.textColor = .mainBlueColor
    phraseLabel.font = UIFont(name: "Avenir", size: 15)

    // *** Setup UI in cell ***
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

    addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.centerX.centerY.top.equalToSuperview()
      make.width.greaterThanOrEqualTo(120)
    }
  }
}
