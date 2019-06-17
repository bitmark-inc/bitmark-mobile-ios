//
//  SelfSizedTableView.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/17/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class SelfSizedTableView: UITableView {
  var maxHeight: CGFloat = UIScreen.main.bounds.size.height

  override var intrinsicContentSize: CGSize {
    return CGSize(width: contentSize.width, height: contentSize.height)
  }
}
