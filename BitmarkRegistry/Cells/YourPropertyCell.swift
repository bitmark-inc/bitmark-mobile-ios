//
//  YourPropertyCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/16/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK

class YourPropertyCell: UITableViewCell {

  // MARK: - Properties
  let dateLabel = UILabel()
  let assetNameLabel = UILabel()
  let issuerLabel = UILabel()

  // MARK: - Init
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Handlers
  func loadWith(_ asset: Asset?, _ bitmark: Bitmark) {
    assetNameLabel.text = asset?.name
    if let confirmed_at = bitmark.confirmed_at {
      dateLabel.text = confirmed_at.string(withFormat: Constant.systemFullFormatDate)
    } else {
      dateLabel.text = "REGISTERING..."
    }
    issuerLabel.text = bitmark.issuer.middleShorten()
  }
}

// MARK: - Setup Views
extension YourPropertyCell {
  fileprivate func setupViews() {
    separatorInset = UIEdgeInsets.zero
    layoutMargins = UIEdgeInsets.zero

    // *** Setup subviews ***
    dateLabel.font = UIFont(name: "Courier", size: 13)
    assetNameLabel.font = UIFont(name: "Avenir-Black", size: 14)
    issuerLabel.font = UIFont(name: "Courier", size: 13)

    let stackView = UIStackView(
      arrangedSubviews: [dateLabel, assetNameLabel, issuerLabel],
      axis: .vertical, spacing: 10)

    // *** Setup UI in view ***
    addSubview(stackView)
    stackView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
          .inset(UIEdgeInsets(top: 18, left: 27, bottom: 18, right: 27))
    }
  }
}
