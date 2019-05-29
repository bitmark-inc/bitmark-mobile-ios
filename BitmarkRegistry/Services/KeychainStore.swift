//
//  KeychainStore.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import KeychainAccess

class KeychainStore {

  // MARK: - Properties
  private static let service = "com.bitmark.registry"
  private static let bitmarkSeedCoreKey = "bitmark_core"
  private static let keychain: Keychain = {
    return Keychain(service: service)
  }()

  // MARK: - Handlers
  static func saveToKeychain(_ seedCore: Data) throws {
    try keychain.set(seedCore, key: bitmarkSeedCoreKey)
  }
}
