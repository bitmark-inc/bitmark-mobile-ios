//
//  FileManager+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/5/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

extension FileManager {
  static var documentDirectoryURL: URL {
    return `default`.urls(for: .documentDirectory, in: .userDomainMask)[0]
  }
}
