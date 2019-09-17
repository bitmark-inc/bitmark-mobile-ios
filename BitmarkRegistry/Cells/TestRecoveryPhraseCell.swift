//
//  HiddenRecoveryPhraseCell.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 6/11/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

protocol ReselectHiddenPhraseBoxDelegate: class {
  func reselectHiddenPhraseBoxCell(_ cell: TestRecoveryPhraseCell)
}

class TestRecoveryPhraseCell: RecoveryPhraseCell {

  // MARK: - Properties
  weak var delegate: ReselectHiddenPhraseBoxDelegate?
  var matchingTestPhraseCell: TestPhraseOptionCell?
  var hiddenPhraseBox: UIView!

  // MARK: - Handlers
  func setData(numericOrder: Int) {
    numericOrderLabel.text = "\(numericOrder)."
  }

  func showHiddenBox() {
    hiddenPhraseBox.isHidden = false
    isUserInteractionEnabled = true
    // reset value when showing hidden box
    phraseLabel.text = ""
    matchingTestPhraseCell = nil
  }

  func setValueForHiddenBox(_ phrase: String, _ matchingTestPhraseCell: TestPhraseOptionCell) {
    hiddenPhraseBox.isHidden = true
    phraseLabel.text = phrase
    phraseLabel.textColor = .mainBlueColor
    self.matchingTestPhraseCell = matchingTestPhraseCell
  }

  func setStyle(state: FieldState) {
    phraseLabel.textColor = state == .success ? .mainBlueColor : .mainRedColor
  }

  func reloadStyle(_ isPhraseHidden: Bool) {
    phraseLabel.textColor = isPhraseHidden ? .mainBlueColor : .gray
  }

  override var isSelected: Bool {
    didSet {
      hiddenPhraseBox.borderWidth = isSelected ? 1 : 0
      if isSelected && hiddenPhraseBox.isHidden {
        delegate?.reselectHiddenPhraseBoxCell(self)
      }
    }
  }

  // MARK: - Setup Views
  override func setupViews() {
    super.setupViews()

    phraseLabel.textColor = .gray

    hiddenPhraseBox = UIView()
    hiddenPhraseBox.backgroundColor = .wildSand
    hiddenPhraseBox.borderColor = .mainBlueColor
    hiddenPhraseBox.isHidden = true

    // *** Setup subviews ***
    mainView.addSubview(hiddenPhraseBox)
    hiddenPhraseBox.snp.makeConstraints { (make) in
      make.leading.trailing.equalTo(phraseLabel)
      make.top.height.equalToSuperview()
    }
  }
}
