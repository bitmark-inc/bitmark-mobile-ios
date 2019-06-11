//
//  HiddenRecoveryPhraseCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

protocol ReselectHiddenPhraseBoxDelegate {
  func reselectHiddenPhraseBoxCell(_ cell: TestRecoveryPhraseCell)
}

class TestRecoveryPhraseCell: RecoveryPhraseCell {

  // MARK: - Properties
  var delegate: ReselectHiddenPhraseBoxDelegate?
  var matchingTestPhraseCell: TestPhraseOptionCell?
  let hiddenPhraseBox: UIView = {
    let view = UIView()
    view.backgroundColor = .wildSand
    view.borderColor = .mainBlueColor
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

  func setValueForHiddenBox(_ phrase: String, _ matchingTestPhraseCell: TestPhraseOptionCell) {
    hiddenPhraseBox.isHidden = true
    phraseLabel.text = phrase
    phraseLabel.textColor = .mainBlueColor
    self.matchingTestPhraseCell = matchingTestPhraseCell
  }

  func setErrorStyle() {
    phraseLabel.textColor = .mainRedColor
  }

  func reloadStyle(_ isPhraseHidden: Bool) {
    phraseLabel.textColor = isPhraseHidden ? .mainBlueColor : .gray
  }

  override var isSelected: Bool {
    didSet {
      hiddenPhraseBox.borderWidth = isSelected ? 1 : 0
      if (isSelected && hiddenPhraseBox.isHidden) { delegate?.reselectHiddenPhraseBoxCell(self) }
    }
  }

  // MARK: - Setup Views
  override func setupViews() {
    super.setupViews()

    phraseLabel.textColor = .gray

    // *** Setup subviews ***
    mainView.addSubview(hiddenPhraseBox)
    hiddenPhraseBox.snp.makeConstraints { (make) in
      make.leading.trailing.equalTo(phraseLabel)
      make.top.height.equalToSuperview()
    }
  }
}
