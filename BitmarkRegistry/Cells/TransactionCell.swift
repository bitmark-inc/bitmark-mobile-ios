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
  var ownerNumberLabel: UILabel!
  var isConfirmed: Bool = false

  // MARK: - Init
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Handlers
  func setData(timestamp: Date?, ownerNumber: String) {
    isConfirmed = timestamp != nil
    timestampLabel.text = CustomUserDisplay.datetime(timestamp) ?? "Waiting to be confirmed"
    ownerNumberLabel.text = CustomUserDisplay.accountNumber(ownerNumber)

    setStyle()
  }

  fileprivate func setStyle() {
    if !isConfirmed {
      timestampLabel.textColor = .dustyGray
      ownerNumberLabel.textColor = .dustyGray
    }
  }

  // MARK: - Setup Views
  fileprivate func setupViews() {
    selectionStyle = .none

    // *** Setup subviews ***
    timestampLabel = CommonUI.infoLabel()

    ownerNumberLabel = CommonUI.infoLabel()
    ownerNumberLabel.textColor = .mainBlueColor

    let stackView = UIStackView(
      arrangedSubviews: [timestampLabel, ownerNumberLabel],
      axis: .horizontal,
      distribution: .fillProportionally
    )

    timestampLabel.snp.makeConstraints { (make) in
      make.width.equalTo(ownerNumberLabel).multipliedBy(1.3)
    }

    // *** Setup UI in view ***
    addSubview(stackView)
    stackView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
          .inset(UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
    }
  }
}
