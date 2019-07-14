//
//  LatestOffsetR.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/13/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import RealmSwift

class LatestOffsetR: Object {

  @objc dynamic var key: String = ""
  @objc dynamic var offset: Int64 = 0

  override static func primaryKey() -> String? {
    return "key"
  }
}
