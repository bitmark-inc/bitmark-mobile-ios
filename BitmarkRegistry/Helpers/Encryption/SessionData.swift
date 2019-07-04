//
//  SessionData.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/28/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

struct SessionData {
  static let CHACHA20_POLY1305_ALGORITHM = "chacha20poly1305"
  let encryptedKey: Data
  let algorithm: String

  static func createSessionData(sender: Account, sessionKey: Data, receiverPublicKey: Data) throws -> SessionData {
    let encryptedSessionKey = try sender.encryptionKey.encrypt(message: sessionKey, receiverPublicKey: receiverPublicKey)

    return SessionData(encryptedKey: encryptedSessionKey,
                       algorithm: CHACHA20_POLY1305_ALGORITHM)
  }

}

