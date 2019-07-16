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

  static func setupDBForCurrentAccount() throws {
    guard let accountNumber = Global.currentAccount?.getAccountNumber() else { return }

    _ = try RealmConfig.user(accountNumber).configuration()
  }

  case user(String)

  func configuration() throws -> Realm.Configuration {
    switch self {
    case .user(let accountNumber):
      return Realm.Configuration(
        fileURL: dbDirectoryURL().appendingPathComponent("main-\(accountNumber).realm"),
        encryptionKey: try getKey(),
        schemaVersion: 1
      )
    }
  }

  fileprivate func dbDirectoryURL() -> URL {
    let dbDirectory = URL(fileURLWithPath: "db", relativeTo: FileManager.sharedDirectoryURL ?? FileManager.documentDirectoryURL)

    if !FileManager.default.fileExists(atPath: dbDirectory.path) {
      do {
        try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: dbDirectory.path)
      } catch {
        ErrorReporting.report(error: error)
      }
    }

    return dbDirectory
  }

  // Reference: https://realm.io/docs/swift/latest/#encryption
  fileprivate func getKey() throws -> Data {
    guard let encryptedDBKey = KeychainStore.getEncryptedDBKeyFromKeychain() else {
      var key = Data(count: 64)
      _ = key.withUnsafeMutableBytes {
        SecRandomCopyBytes(kSecRandomDefault, 64, $0)
      }

      try KeychainStore.saveEncryptedDBKeyToKeychain(key)

      return key
    }

    return encryptedDBKey
  }
}