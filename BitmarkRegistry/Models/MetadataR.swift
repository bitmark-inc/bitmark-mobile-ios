//
//  MetadataR.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 7/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RealmSwift

class MetadataR: Object {
  // MARK: - Properties
  @objc dynamic var key: String = ""
  @objc dynamic var value: String = ""
}
