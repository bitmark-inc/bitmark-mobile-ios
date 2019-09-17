//
//  SessionData.swift
//  Bitmark
//
//  Created by Thuyen Truong on 6/28/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK

struct SessionData {
  static let Chacha20Poly1305Algorithm = "chacha20poly1305"
  let encryptedKey: Data
  let algorithm: String

  static func createSessionData(sender: Account, sessionKey: Data, algorithm: String = Chacha20Poly1305Algorithm, receiverPublicKey: Data) throws -> SessionData {
    let encryptedSessionKey = try sender.encryptionKey.encrypt(message: sessionKey, receiverPublicKey: receiverPublicKey)

    return SessionData(encryptedKey: encryptedSessionKey, algorithm: algorithm)
  }
}
