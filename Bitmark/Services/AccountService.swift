//
//  AccountService.swift
//  Bitmark
//
//  Created by Thuyen Truong on 5/29/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import RxSwift

class AccountService {
  static let shared = AccountService()
  let disposeBag = DisposeBag()

  static func createNewAccount(completion: @escaping (Account?, Error?) -> Void) throws {
    let account = try Account()

    AccountKeyService.registerEncryptionPublicKey(account: account) {
      completion(account, $0)
    }
  }

  func existsCurrentAccount() -> Single<Bool> {
    guard UserSetting.shared.isUserLoggedIn() else {
      do {
        Global.log.info("Remove seed core from Keychain")
        try KeychainStore.removeSeedCoreFromKeychain()
      } catch {
        Global.log.error(error)
      }
      return Single<Bool>.just(false)
    }

    return KeychainStore.getSeedDataFromKeychain()
      .map({ (seedCore) -> Account? in
        if let accountVersion = UserSetting.shared.getAccountVersion(),
          let seedCore = seedCore {
          do {
            let seed = try Seed.fromCore(seedCore, version: accountVersion)
            return try Account(seed: seed)
          } catch {
            Global.log.error(error)
          }
        }
        return nil
      })
      .flatMap({ (account) -> Single<Bool> in
        Global.currentAccount = account
        return Single<Bool>.just(account != nil)
      })
  }

  static func getAccount(phrases: [String]) throws -> Account {
    return try Account(recoverPhrase: phrases, language: .english)
  }
}
