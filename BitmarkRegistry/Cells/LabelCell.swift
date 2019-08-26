//
//  LabelCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/13/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class LabelCell: UITableViewCell {
  var label: UILabel!

  // MARK: - Init
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup Views
  fileprivate func setupViews() {
    // *** Setup subviews ***
    label = UILabel()
    label.font = UIFont(name: Constant.andaleMono, size: 15)
    label.textColor = .mainBlueColor

    // *** Setup UI in view ***
    addSubview(label)
    label.snp.makeConstraints { (make) in
      make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0))
    }
  }
}
