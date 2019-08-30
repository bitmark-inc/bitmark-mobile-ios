//
//  KeychainStore.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import KeychainAccess
import RxSwift

class KeychainStore {

  // MARK: - Properties
  private static let bitmarkSeedCoreKey = "bitmark_core"
  private static let bitmarkSeedCoreWithoutAuthentication = "bitmark_core_no_authentication" // migrating for old-version app
  private static let bitmarkEncryptedDBKey = "bitmark_encrypted_db_key"
  private static let seedValidDuration = 30 // minutes
  private static let keychain: Keychain = {
    return Keychain(service: Bundle.main.bundleIdentifier!)
                    .authenticationPrompt("YourAuthorizationIsRequired".localized())
  }()
  private static let expiryTimeKey = "expiryTimeKey"

  // MARK: - Handlers
  // *** seed Core ***
  static func saveToKeychain(_ seedCore: Data) -> Completable {
    return Completable.create(subscribe: { (completion) -> Disposable in
      DispatchQueue.global().async {
        do {
          if UserSetting.shared.getTouchFaceIdSetting() {
            try keychain.accessibility(.whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
              .set(seedCore, key: bitmarkSeedCoreKey)
          } else {
            try keychain.set(seedCore, key: bitmarkSeedCoreKey)
          }
          completion(.completed)
        } catch {
          completion(.error(error))
        }
      }
      return Disposables.create()
    })
  }

  static func removeSeedCoreFromKeychain() throws {
    try keychain.remove(bitmarkSeedCoreKey)
    try keychain.remove(bitmarkSeedCoreWithoutAuthentication)
  }

  static func getSeedDataFromKeychain() -> Single<Data?> {
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
}
