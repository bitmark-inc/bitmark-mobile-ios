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
  private static let bitmarkSeedCoreWithoutAuthenticartion = "bitmark_core_no_authentication" // migrating for old-version app
  private static let bitmarkEncryptedDBKey = "bitmark_encrypted_db_key"
  private static let keychain: Keychain = {
    return Keychain(service: service)
  }()

  // MARK: - Handlers
  // *** seed Core ***
  static func saveToKeychain(_ seedCore: Data) throws {
    try keychain.set(seedCore, key: bitmarkSeedCoreKey)
  }

  static func removeSeedCoreFromKeychain() throws {
    try keychain.remove(bitmarkSeedCoreKey)
  }

  static func getSeedDataFromKeychain() -> Data? {
    return (getDataFromKeychain(key: bitmarkSeedCoreKey) ?? getDataFromKeychain(key: bitmarkSeedCoreWithoutAuthenticartion))
  }

  // *** Encrypted db key ***
  static func saveEncryptedDBKeyToKeychain(_ encryptedKey: Data) throws {
    try keychain.accessibility(Accessibility.afterFirstUnlock)
                .set(encryptedKey, key: bitmarkEncryptedDBKey)
  }

  static func getEncryptedDBKeyFromKeychain() -> Data? {
    return getDataFromKeychain(key: bitmarkEncryptedDBKey)
  }

  fileprivate static func getDataFromKeychain(key: String) -> Data? {
    do {
      return try keychain.getData(key)
    } catch {
      ErrorReporting.report(error: error)
      return nil
    }
  }
}
