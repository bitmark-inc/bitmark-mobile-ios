//
//  RealmConfig.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/14/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import RealmSwift

enum RealmConfig {
  case user(String)

  var configuration: Realm.Configuration {
    switch self {
    case .user(let accountNumber):
      return Realm.Configuration(
        fileURL: FileManager.documentDirectoryURL.appendingPathComponent("main-\(accountNumber).realm"),
        schemaVersion: 1
      )
    }
  }
}
