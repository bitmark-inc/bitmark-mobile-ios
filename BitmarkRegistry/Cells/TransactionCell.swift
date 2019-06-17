//
//  TransactionCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/17/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class TransactionCell: UITableViewCell {

  // MARK: - Properties
  var timestampLabel: UILabel!
  var ownerLabel: UILabel!

  // MARK: - Init
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Handlers
  func setData(timestamp: Date, owner: String) {
    timestampLabel.text = timestamp.string(withFormat: Constant.systemFullFormatDate)
    ownerLabel.text = owner.middleShorten()
  }

  // MARK: - Setup Views
  fileprivate func setupViews() {
    // *** Setup subviews ***
    timestampLabel = CommonUI.infoLabel()
    timestampLabel.textColor = .mainBlueColor

    ownerLabel = CommonUI.infoLabel()
    ownerLabel.textColor = .mainBlueColor

    let stackView = UIStackView(
      arrangedSubviews: [timestampLabel, ownerLabel],
      axis: .horizontal,
      distribution: .fillProportionally
    )

    timestampLabel.snp.makeConstraints { (make) in
      make.width.equalTo(ownerLabel).multipliedBy(1.3)
    }

    // *** Setup UI in view ***
    addSubview(stackView)
    stackView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
        .inset(UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
    }
  }
}
