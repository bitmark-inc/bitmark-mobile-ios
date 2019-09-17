//
//  FileManager+Extension.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 6/16/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

extension FileManager {
  static var documentDirectoryURL: URL {
    return `default`.urls(for: .documentDirectory, in: .userDomainMask)[0]
  }

  static var sharedDirectoryURL: URL? {
    guard let appGroupIdentifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String else { return nil }
    return `default`.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
  }
}
