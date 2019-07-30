//
//  MetadataDetailCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/17/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class MetadataDetailCell: UITableViewCell {

  // MARK: - Properties
  var labelLabel: UILabel!
  var descriptionLabel: UILabel!
  var isBitmarkConfirmed: Bool = false {
    didSet {
      labelLabel.textColor = isBitmarkConfirmed ? .black : .dustyGray
    }
  }

  // MARK: - Init
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Handlers
  func setData(_ metadataR: MetadataR) {
    labelLabel.text = metadataR.key + ":"
    descriptionLabel.text = metadataR.value
    labelLabel.lineHeightMultiple(1.2)
    descriptionLabel.lineHeightMultiple(1.2)
  }

  // MARK: - Setup Views
  fileprivate func setupViews() {
    // *** Setup subviews ***
    labelLabel = CommonUI.infoLabel()
    labelLabel.numberOfLines = 0

    descriptionLabel = UILabel()
    descriptionLabel.numberOfLines = 0
    descriptionLabel.font = UIFont(name: "Avenir", size: 14)
    descriptionLabel.textColor = .dustyGray

    let stackView = UIStackView(
      arrangedSubviews: [labelLabel, descriptionLabel],
      axis: .horizontal,
      spacing: 5,
      distribution: .fillProportionally
    )

    labelLabel.snp.makeConstraints { (make) in
      make.width.equalTo(descriptionLabel).multipliedBy(0.7)
    }

    // *** Setup UI in view ***
    addSubview(stackView)
    stackView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
          .inset(UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0))
    }
  }
}
