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
  static let Chacha20Poly1305Algorithm = "chacha20poly1305"
  let encryptedKey: Data
  let algorithm: String

  static func createSessionData(sender: Account, sessionKey: Data, receiverPublicKey: Data) throws -> SessionData {
    let encryptedSessionKey = try sender.encryptionKey.encrypt(message: sessionKey, receiverPublicKey: receiverPublicKey)

    return SessionData(encryptedKey: encryptedSessionKey,
                       algorithm: Chacha20Poly1305Algorithm)
  }
}
