//
//  PhraseOptionCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

protocol SelectPhraseOptionProtocol {
  func selectPhraseOptionCell(_ phraseOptionCell: PhraseOptionCell)
}

class PhraseOptionCell: UICollectionViewCell {

  // MARK: - Properties
  @IBOutlet weak var phraseOptionBox: UIButton!
  var delegate: SelectPhraseOptionProtocol?
  var matchingTestPhraseCell: PhraseOptionCell?

  // MARK: - Handlers
  @IBAction func selectPhraseOption(_ sender: UIButton) {
    delegate?.selectPhraseOptionCell(self)
  }
}
