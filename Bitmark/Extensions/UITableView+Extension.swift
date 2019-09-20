//
//  UITableView+Extension.swift
//  Bitmark
//
//  Created by Thuyen Truong on 7/14/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RealmSwift

extension IndexPath {
  static func fromRow(_ row: Int) -> IndexPath {
    return IndexPath(row: row, section: 0)
  }
}

extension UITableView {
  func apply<T>(changes: RealmCollectionChange<Results<T>>) {
    switch changes {
    case .initial:
      reloadData()
    case .update(_, let deletions, let insertions, let updates):
      applyChanges(deletions: deletions, insertions: insertions, updates: updates)
    case .error(let error):
      Global.log.error(error)
    }
  }

  func applyChanges(section: Int = 0, deletions: [Int], insertions: [Int], updates: [Int]) {
    beginUpdates()
    deleteRows(at: deletions.map(IndexPath.fromRow), with: .automatic)
    insertRows(at: insertions.map(IndexPath.fromRow), with: .automatic)
    reloadRows(at: updates.map(IndexPath.fromRow), with: .none)
    endUpdates()
  }
}
