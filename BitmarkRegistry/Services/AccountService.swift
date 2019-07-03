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

  static func createNewAccount(completion: @escaping (Account?, Error?) -> Void) throws  {
    let account = try Account()

    AccountKeyService.registerEncryptionPublicKey(account: account) {
      completion(account, $0)
    }
  }

  static func existsCurrentAccount() -> Bool {
    return getCurrentAccount() != nil
  }

  static func getCurrentAccount() -> Account? {
    var account: Account? = nil
    let seedCore = KeychainStore.getSeedDataFromKeychain()
    if let seedCore = seedCore {
      do {
        let seed = try Seed.fromCore(seedCore, version: .v2)
        account = try Account(seed: seed)
      } catch let e {
        print(e)
        ErrorReporting.report(error: e)
      }
    }
    Global.currentAccount = account
    return account
  }
}
