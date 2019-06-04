//
//  RecoveryPhraseCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

protocol ReselectHiddenPhraseBoxProtocol {
  func reselectCell(_ cell: RecoveryPhraseCell)
}

class RecoveryPhraseCell: UICollectionViewCell {

  // MARK: - Properties
  @IBOutlet weak var noLabel: UILabel!
  @IBOutlet weak var phraseLabel: UILabel!
  @IBOutlet weak var hiddenPhraseBox: UIView!
  var delegate: ReselectHiddenPhraseBoxProtocol?
  var matchingTestPhraseCell: PhraseOptionCell?

  // MARK: - Handlers
  func setData(no: Int, phrase: String) {
    noLabel.text = "\(no)."
    phraseLabel.text = phrase
  }

  func showHiddenBox(no: Int) {
    noLabel.text = "\(no)."
    hiddenPhraseBox.isHidden = false
    isUserInteractionEnabled = true
    // reset value when showing hidden box
    phraseLabel.text = ""
    matchingTestPhraseCell = nil
  }

  func setValueForHiddenBox(_ phrase: String, _ matchingTestPhraseCell: PhraseOptionCell) {
    hiddenPhraseBox.isHidden = true
    phraseLabel.text = phrase
    phraseLabel.textColor = UIColor.mainBlueColor
    self.matchingTestPhraseCell = matchingTestPhraseCell
  }

  func setErrorStyle() {
    phraseLabel.textColor = UIColor.red
  }

  func reloadStyle(_ isPhraseHidden: Bool) {
    phraseLabel.textColor = isPhraseHidden ? .mainBlueColor : .mainGrayColor
  }

  override var isSelected: Bool {
    didSet {
      hiddenPhraseBox?.layer.borderWidth = isSelected ? 1 : 0
      if (isSelected && hiddenPhraseBox.isHidden) { delegate?.reselectCell(self) }
    }
  }
}
