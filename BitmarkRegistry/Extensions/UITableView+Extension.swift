//
//  UITableView+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/14/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

extension IndexPath {
  static func fromRow(_ row: Int) -> IndexPath {
    return IndexPath(row: row, section: 0)
  }
}

extension UITableView {
  func applyChanges(section: Int = 0, deletions: [Int], insertions: [Int], updates: [Int]) {
    beginUpdates()
    deleteRows(at: deletions.map(IndexPath.fromRow), with: .automatic)
    insertRows(at: insertions.map(IndexPath.fromRow), with: .automatic)
    reloadRows(at: updates.map(IndexPath.fromRow), with: .none)
    endUpdates()
  }
}
