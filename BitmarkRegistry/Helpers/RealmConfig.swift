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

  static func currentRealm() throws -> Realm? {
    guard let accountNumber = Global.currentAccount?.getAccountNumber() else { return nil }
    let userConfiguration = try RealmConfig.user(accountNumber).configuration()
    Global.log.info("UserRealm: \(userConfiguration)")
    return try Realm(configuration: userConfiguration)
  }

  case user(String)

  func configuration() throws -> Realm.Configuration {
    switch self {
    case .user(let accountNumber):
      return Realm.Configuration(
        fileURL: dbDirectoryURL().appendingPathComponent("\(accountNumber).realm"),
        encryptionKey: try getKey(),
        schemaVersion: 1
      )
    }
  }

  fileprivate func dbDirectoryURL() -> URL {
    ErrorReporting.breadcrumbs(info: "get db Directory URL", category: .dbData)
    let dbDirectory = URL(fileURLWithPath: "db", relativeTo: FileManager.sharedDirectoryURL ?? FileManager.documentDirectoryURL)

    do {
      if KeychainStore.getEncryptedDBKeyFromKeychain() == nil && FileManager.default.fileExists(atPath: dbDirectory.path) {
        try FileManager.default.removeItem(at: dbDirectory)
      }

      if !FileManager.default.fileExists(atPath: dbDirectory.path) {
        try FileManager.default.createDirectory(at: dbDirectory, withIntermediateDirectories: true)
        try FileManager.default.setAttributes([FileAttributeKey.protectionKey: FileProtectionType.none], ofItemAtPath: dbDirectory.path)
      }
    } catch {
      ErrorReporting.report(error: error)
    }

    ErrorReporting.breadcrumbs(info: "get db Directory URL successfully", category: .dbData)
    return dbDirectory
  }

  // Reference: https://realm.io/docs/swift/latest/#encryption
  fileprivate func getKey() throws -> Data {
    guard let encryptedDBKey = KeychainStore.getEncryptedDBKeyFromKeychain() else {
      var key = Data(count: 64)
      _ = key.withUnsafeMutableBytes({ (ptr: UnsafeMutableRawBufferPointer) -> Void in
        guard let pointer = ptr.bindMemory(to: UInt8.self).baseAddress else { return }
        _ = SecRandomCopyBytes(kSecRandomDefault, 64, pointer)
      })

      try KeychainStore.saveEncryptedDBKeyToKeychain(key)

      return key
    }

    return encryptedDBKey
  }
}
