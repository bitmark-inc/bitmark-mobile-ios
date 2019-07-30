//
//  TransactionListCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/5/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK

class TransactionListCell: UITableViewCell {

  // MARK: - Properties
  var txTitle: UILabel!
  var completedMarkTitle: UIImageView!
  var txTimestampLabel: UILabel!
  var propertyNameLabel: UILabel!
  var txTypeLabel: UILabel!
  var accountFromLabel: UILabel!
  var accountToTitleLabel: UILabel!
  var accountToLabel: UILabel!

  // MARK: - Init
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Data Handlers
  func loadWith(_ txR: TransactionR) {
    if txR.isTransferTx() {
      txTypeLabel.text = "P2P TRANSFER"
      txTitle.text = "SEND"
      accountFromLabel.text = CustomUserDisplay.accountNumber(txR.previousOwner)
      accountToTitleLabel.text = "TO"
      accountToLabel.text = CustomUserDisplay.accountNumber(txR.owner)
    } else {
      txTypeLabel.text = "PROPERTY ISSUANCE"
      txTitle.text = "ISSUANCE"
      accountFromLabel.text = CustomUserDisplay.accountNumber(txR.owner)
    }

    propertyNameLabel.text = txR.assetR?.name

    if let confirmedAt = txR.confirmedAt {
      txTimestampLabel.text = CustomUserDisplay.datetime(confirmedAt)
      txTitle.isHidden = true
      completedMarkTitle.isHidden = false
    } else {
      txTimestampLabel.text = "PENDING..."
      txTitle.isHidden = false
      completedMarkTitle.isHidden = true
    }

    setupTitleStyle(with: txR.status)
  }
}

// MARK: - Setup Views
extension TransactionListCell {
  fileprivate func setupTitleStyle(with txStatus: String) {
    if txStatus == TransactionStatus.confirmed.rawValue {
      txTitle.textColor = .mainBlueColor
      txTimestampLabel.textColor = .mainBlueColor
    } else {
      txTitle.textColor = .dustyGray
      txTimestampLabel.textColor = .dustyGray
    }
  }

  fileprivate func setupViews() {
    separatorInset = UIEdgeInsets.zero
    layoutMargins = UIEdgeInsets.zero
    selectionStyle = .none

    // *** Setup subviews ***
    let heading = setupHeading()
    let propertyNameRow = setupPropertyNameRow()
    let infoView = setupInfoView()

    let mainView = UIView()
    mainView.addSubview(heading)
    mainView.addSubview(propertyNameRow)
    mainView.addSubview(infoView)

    heading.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    propertyNameRow.snp.makeConstraints { (make) in
      make.top.equalTo(heading.snp.bottom).offset(10)
      make.leading.trailing.equalToSuperview()
    }

    infoView.snp.makeConstraints { (make) in
      make.top.equalTo(propertyNameRow.snp.bottom).offset(10)
      make.leading.trailing.bottom.equalToSuperview()
    }

    // *** Setup UI in view ***
    addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
          .inset(UIEdgeInsets(top: 18, left: 27, bottom: 18, right: 27))
    }
  }

  fileprivate func setupHeading() -> UIStackView {
    txTitle = CommonUI.infoLabel()
    completedMarkTitle = UIImageView(image: UIImage(named: "completed-mark"))
    completedMarkTitle.contentMode = .left
    txTimestampLabel = CommonUI.infoLabel()

    let stackview = UIStackView(
      arrangedSubviews: [txTitle, completedMarkTitle, txTimestampLabel],
      axis: .horizontal,
      distribution: .fillProportionally
    )

    txTitle.snp.makeConstraints { (make) in
      make.width.equalTo(txTimestampLabel).multipliedBy(0.7)
      make.width.equalTo(completedMarkTitle)
    }

    return stackview
  }

  fileprivate func setupPropertyNameRow() -> UIStackView {
    let propertyNameTitle = CommonUI.infoLabel(text: "PROPERTY")
    propertyNameLabel = UILabel()
    propertyNameLabel.font = UIFont(name: "Avenir-Black", size: 14)

    let stackview = UIStackView(
      arrangedSubviews: [propertyNameTitle, propertyNameLabel],
      axis: .horizontal,
      distribution: .fillProportionally
    )

    propertyNameTitle.snp.makeConstraints { (make) in
      make.width.equalTo(propertyNameLabel).multipliedBy(0.7)
    }

    return stackview
  }

  fileprivate func setupInfoView() -> UIStackView {
    let rowSpacing: CGFloat = 3
    accountToTitleLabel = CommonUI.infoLabel()
    let titleStackView = UIStackView(
      arrangedSubviews: [
        CommonUI.infoLabel(text: "TYPE"),
        CommonUI.infoLabel(text: "FROM"),
        accountToTitleLabel
      ],
      axis: .vertical, spacing: rowSpacing, alignment: .leading, distribution: .fill
    )

    txTypeLabel = CommonUI.infoLabel()
    accountFromLabel = CommonUI.infoLabel()
    accountToLabel = CommonUI.infoLabel()

    let valueStackView = UIStackView(
      arrangedSubviews: [txTypeLabel, accountFromLabel, accountToLabel],
      axis: .vertical, spacing: rowSpacing, alignment: .leading, distribution: .fill
    )

    let infoView = UIStackView(
      arrangedSubviews: [titleStackView, valueStackView],
      axis: .horizontal,
      distribution: .fillProportionally
    )

    titleStackView.snp.makeConstraints { (make) in
      make.width.equalTo(valueStackView).multipliedBy(0.7)
    }

    return infoView
  }
}
