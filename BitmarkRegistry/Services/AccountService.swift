//
//  AccountService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class AccountService {

  static func createNewAccount(completion: @escaping (Account?, Error?) -> Void) throws {
    let account = try Account()

    AccountKeyService.registerEncryptionPublicKey(account: account) {
      completion(account, $0)
    }
  }

  static func existsCurrentAccount() -> Bool {
    if UserSetting.shared.isUserLoggedIn() {
      return getCurrentAccount() != nil
    } else {
      return false
    }
  }

  static func getCurrentAccount() -> Account? {
    var account: Account?
    let seedCore = KeychainStore.getSeedDataFromKeychain()
    if let accountVersion = UserSetting.shared.getAccountVersion(),
       let seedCore = seedCore {
      do {
        let seed = try Seed.fromCore(seedCore, version: accountVersion)
        account = try Account(seed: seed)
      } catch {
        ErrorReporting.report(error: error)
      }
    }
    Global.currentAccount = account
    return account
  }

  static func getAccount(phrases: [String]) throws -> Account {
    return try Account(recoverPhrase: phrases, language: .english)
  }
}
