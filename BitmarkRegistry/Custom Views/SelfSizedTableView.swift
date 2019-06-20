//
//  SelfSizedTableView.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/17/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//  Reference: https://medium.com/@dushyant_db/swift-4-recipe-self-sizing-table-view-2635ac3df8ab
//

import UIKit

/**
 SelfSizedTableView: Using to let tableview adjust the height to show all the rows
 Such as: metadata table shows in bitmark detail screen
 */
class SelfSizedTableView: UITableView {
  var maxHeight: CGFloat = UIScreen.main.bounds.size.height

  override var intrinsicContentSize: CGSize {
    return CGSize(width: contentSize.width, height: contentSize.height)
  }
}
