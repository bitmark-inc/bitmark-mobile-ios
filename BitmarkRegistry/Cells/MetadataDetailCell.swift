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

  // MARK: - Init
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Handlers
  func setData(_ metadata: (label: String, description: String)) {
    labelLabel.text = metadata.label + ":"
    descriptionLabel.text = metadata.description
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

    let stackView = UIStackView(
      arrangedSubviews: [labelLabel, descriptionLabel],
      axis: .horizontal,
      spacing: 5,
      distribution: .fillProportionally
    )

    labelLabel.snp.makeConstraints { $0.width.equalToSuperview().multipliedBy(0.4) }
    descriptionLabel.snp.makeConstraints { $0.width.equalToSuperview().multipliedBy(0.6) }

    // *** Setup UI in view ***
    addSubview(stackView)
    stackView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
          .inset(UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0))
    }
  }
}
