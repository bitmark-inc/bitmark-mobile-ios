//
//  TestPhraseOptionCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class TestPhraseOptionCell: UICollectionViewCell {

  // MARK: - Properties
  static let phraseOptionFont = UIFont(name: "Avenir", size: 15)!

  let phraseOptionBox: UIButton = {
    let button = UIButton()
    button.titleLabel?.font = phraseOptionFont
    button.setTitleColor(.mainBlueColor, for: .normal)
    return button
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

  // MARK: - Setup Views
  func setupViews() {
    borderColor = .mainBlueColor
    borderWidth = 0.5
    cornerRadius = 2.0

    addSubview(phraseOptionBox)
    phraseOptionBox.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }
  }
}
