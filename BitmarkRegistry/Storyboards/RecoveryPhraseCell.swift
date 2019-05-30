//
//  RecoveryPhraseCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class RecoveryPhraseCell: UICollectionViewCell {

  // MARK: - Properties
  @IBOutlet weak var noLabel: UILabel!
  @IBOutlet weak var phraseLabel: UILabel!
  @IBOutlet weak var hiddenPhraseBox: UIButton!


  // MARK: - Handlers
  func setData(no: Int, phrase: String) {
    noLabel.text = "\(no)."
    phraseLabel.text = phrase
  }

  func showHiddenBox(no: Int) {
    noLabel.text = "\(no)."
    hiddenPhraseBox.isHidden = false
  }
}
