//
//  MetadataR.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/13/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import RealmSwift

class MetadataR: Object {
  // MARK: - Properties
  @objc dynamic var key: String = ""
  @objc dynamic var value: String = ""
}
