//
//  BlockR.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/15/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK
import RealmSwift

class BlockR: Object {

  // MARK: - Properties
  @objc dynamic var number: Int64 = 0
  @objc dynamic var createdAt: Date = Date()

  override static func primaryKey() -> String? {
    return "number"
  }

  // MARK: - Init
  convenience init(block: Block) {
    self.init()
    self.number = block.number
    self.createdAt = block.created_at
  }
}
