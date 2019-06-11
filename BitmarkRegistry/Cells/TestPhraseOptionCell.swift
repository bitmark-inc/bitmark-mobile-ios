//
//  TestPhraseOptionCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

protocol SelectPhraseOptionDelegate {
  func selectPhraseOptionCell(_ phraseOptionCell: TestPhraseOptionCell)
}

class TestPhraseOptionCell: UICollectionViewCell {

  // MARK: - Properties
  static let phraseOptionFont = UIFont(name: "Avenir", size: 15)!
  var delegate: SelectPhraseOptionDelegate?

  lazy var phraseOptionBox: UIButton = {
    let button = UIButton()
    button.titleLabel?.font = TestPhraseOptionCell.phraseOptionFont
    button.setTitleColor(.mainBlueColor, for: .normal)
    button.addTarget(self, action: #selector(TestPhraseOptionCell.selectPhraseOption), for: .touchUpInside)
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

  // MARK: - Handlers
  @objc func selectPhraseOption(_ sender: UIButton) {
    delegate?.selectPhraseOptionCell(self)
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
