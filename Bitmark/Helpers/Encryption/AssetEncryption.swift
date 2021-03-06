//
//  AssetEncryption.swift
//  Bitmark
//
//  Created by Thuyen Truong on 6/28/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK

struct AssetEncryption {
  let key: Data
  private let nonce = Data([UInt8](repeating: 0x00, count: 12))

  init() {
    var key = Data(count: 32)
    _ = key.withUnsafeMutableBytes({ (ptr: UnsafeMutableRawBufferPointer) -> Void in
      guard let pointer = ptr.bindMemory(to: UInt8.self).baseAddress else { return }
      _ = SecRandomCopyBytes(kSecRandomDefault, 32, pointer)
    })
    self.key = key
  }

  init(from sessionData: SessionData, receiverAccount: Account, senderEncryptionPublicKey: Data) throws {
    self.key = try receiverAccount.encryptionKey.decrypt(cipher: sessionData.encryptedKey, senderPublicKey: senderEncryptionPublicKey)
  }

  func encryptData(_ data: Data) throws -> Data {
    return try Chacha20Poly1305.seal(withKey: key, nonce: nonce, plainText: data, additionalData: nil)
  }

  func decryptData(_ data: Data) throws -> Data {
    return try Chacha20Poly1305.open(withKey: key, nonce: nonce, cipherText: data, additionalData: nil)
  }

  func getSessionData(sender: Account, receiverPublicKey: Data) throws -> SessionData {
    return try SessionData.createSessionData(sender: sender, sessionKey: key, receiverPublicKey: receiverPublicKey)
  }
}
