//
//  HiddenRecoveryPhraseCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class TestRecoveryPhraseCell: RecoveryPhraseCell {

  // MARK: - Properties
  let hiddenPhraseBox: UIView = {
    let view = UIView()
    view.backgroundColor = .wildSand
    view.isHidden = true
    return view
  }()

  // MARK: - Handlers
  func setData(numericOrder: Int) {
    numericOrderLabel.text = "\(numericOrder)."
  }

  func showHiddenBox() {
    hiddenPhraseBox.isHidden = false
    isUserInteractionEnabled = true
    // reset value when showing hidden box
    phraseLabel.text = ""
  }

  // MARK: - Setup Views
  override func setupViews() {
    super.setupViews()

    // *** Setup subviews ***
    mainView.addSubview(hiddenPhraseBox)
    hiddenPhraseBox.snp.makeConstraints { (make) in
      make.leading.trailing.equalTo(phraseLabel)
      make.top.height.equalToSuperview()
    }
  }
}
