//
//  FileManager+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/16/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

extension FileManager {
  static var documentDirectoryURL: URL {
    return `default`.urls(for: .documentDirectory, in: .userDomainMask)[0]
  }

  static var sharedDirectoryURL: URL? {
    let appGroupIdentifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as! String
    return `default`.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
  }
}
