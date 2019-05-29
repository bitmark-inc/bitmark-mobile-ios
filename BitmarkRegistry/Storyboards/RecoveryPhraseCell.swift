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

  // MARK: - Handlers
  func setData(no: Int, phrase: String) {
    noLabel.text = "\(no)."
    phraseLabel.text = phrase
  }
}
