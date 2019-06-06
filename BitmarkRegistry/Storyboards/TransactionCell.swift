//
//  TransactionCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/6/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class TransactionCell: UITableViewCell {

  @IBOutlet weak var timestampLabel: UILabel!
  @IBOutlet weak var ownerLabel: UILabel!

  func setData(timestamp: Date, owner: String) {
    timestampLabel.text = timestamp.format()
    ownerLabel.text = owner.middleShorten()
  }
}
