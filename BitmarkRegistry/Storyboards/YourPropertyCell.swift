//
//  YourPropertyCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/5/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK

class YourPropertyCell: UITableViewCell {

  // MARK: - Properties
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var assetNameLabel: UILabel!
  @IBOutlet weak var issuerLabel: UILabel!

  // MARK: - Handlers
  func loadWith(_ asset: Asset?, _ bitmark: Bitmark) {
    assetNameLabel.text = asset?.name
    if let confirmed_at = bitmark.confirmed_at {
      dateLabel.text = confirmed_at.format()
    }
    issuerLabel.text = "[\(bitmark.issuer.middleShorten())]"
  }
}
