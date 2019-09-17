//
//  KeychainStore.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 5/29/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import KeychainAccess
import RxSwift

class KeychainStore {

  // MARK: - Properties
  private static let bitmarkSeedCoreKey = "bitmark_core"
  private static let bitmarkSeedCoreWithoutAuthentication = "bitmark_core_no_authentication" // migrating for old-version app
  private static let bitmarkEncryptedDBKey = "bitmark_encrypted_db_key"
  private static func iCloudSettingKey(_ accountNumber: String) -> String {
    return "icloud_setting_\(accountNumber)"
  }

  private static let seedValidDuration = 30 // minutes
  private static let keychain: Keychain = {
    return Keychain(service: Bundle.main.bundleIdentifier!)
                    .authenticationPrompt("YourAuthorizationIsRequired".localized())
  }()
  private static let expiryTimeKey = "expiryTimeKey"

  // MARK: - Handlers
  // *** seed Core ***
  static func saveToKeychain(_ seedCore: Data) -> Completable {
    ErrorReporting.breadcrumbs(info: "save SeedCore into keychain", category: .keychain)

    return Completable.create(subscribe: { (completion) -> Disposable in
      DispatchQueue.global().async {
        do {
          try removeSeedCoreFromKeychain()
          if UserSetting.shared.getTouchFaceIdSetting() {
            try keychain.accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
              .set(seedCore, key: bitmarkSeedCoreKey)
          } else {
            try keychain.set(seedCore, key: bitmarkSeedCoreKey)
          }
          ErrorReporting.breadcrumbs(info: "finished saving SeedCore into keychain", category: .keychain)
          completion(.completed)
        } catch {
          completion(.error(error))
        }
      }
      return Disposables.create()
    })
  }

  static func removeSeedCoreFromKeychain() throws {
    ErrorReporting.breadcrumbs(info: "remove SeedCore from keychain", category: .keychain)
    defer { ErrorReporting.breadcrumbs(info: "finished removing SeedCore into keychain", category: .keychain) }

    try keychain.remove(bitmarkSeedCoreKey)
    try keychain.remove(bitmarkSeedCoreWithoutAuthentication)
  }

  static func getSeedDataFromKeychain() -> Single<Data?> {
    ErrorReporting.breadcrumbs(info: "get SeedCore from keychain", category: .keychain)

    return Single<Data?>.create(subscribe: { (single) -> Disposable in
      DispatchQueue.global().async {
        do {
          let seedData = try keychain.getData(bitmarkSeedCoreKey)
                          ?? keychain.getData(bitmarkSeedCoreWithoutAuthentication)
          if seedData != nil {
            UserDefaults.standard.set(Calendar.current.date(
              byAdding: .minute, value: seedValidDuration, to: Date()),
              forKey: expiryTimeKey
            )
          }
          ErrorReporting.breadcrumbs(info: "finished getting SeedCore from keychain", category: .keychain)
          single(.success(seedData))
        } catch {
          single(.error(error))
        }
      }
      return Disposables.create()
    })
  }

  static func isAccountExpired() -> Bool {
    guard let expiryTime = UserDefaults.standard.date(forKey: expiryTimeKey) else { return true }
    return expiryTime < Date()
  }

  // *** Encrypted db key ***
  static func saveEncryptedDBKeyToKeychain(_ encryptedKey: Data) throws {
    ErrorReporting.breadcrumbs(info: "save EncryptedDBKey into keychain", category: .keychain)
    defer { ErrorReporting.breadcrumbs(info: "finished saving EncryptedDBKey into keychain", category: .keychain) }

    try keychain.accessibility(Accessibility.afterFirstUnlock)
                .set(encryptedKey, key: bitmarkEncryptedDBKey)
  }

  static func getEncryptedDBKeyFromKeychain() -> Data? {
    do {
      return try keychain.getData(bitmarkEncryptedDBKey)
    } catch {
      return nil
    }
  }

  // *** user's setting to save asset files to icloud drive or not
  static func saveiCloudSetting(_ accountNumber: String, isEnable: Bool) throws {
    ErrorReporting.breadcrumbs(info: "save iCloudSetting into keychain", category: .keychain)
    defer { ErrorReporting.breadcrumbs(info: "finished saving iCloudSetting into keychain", category: .keychain) }

    let key = iCloudSettingKey(accountNumber)
    try keychain.remove(key)
    try keychain.accessibility(.afterFirstUnlock)
                .set(String(isEnable), key: key)
  }

  static func getiCloudSettingFromKeychain(_ accountNumber: String) -> Bool? {
    do {
      return Bool(try keychain.getString(iCloudSettingKey(accountNumber)) ?? "")
    } catch {
      return nil
    }
  }
}
