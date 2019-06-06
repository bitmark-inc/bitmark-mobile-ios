//
//  MetadataListCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/6/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class MetadataShowCell: UITableViewCell {

  @IBOutlet weak var labelLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!

  func setData(label: String, description: String) {
    labelLabel.text = label.uppercased() + ":"
    descriptionLabel.text = description
  }
}
