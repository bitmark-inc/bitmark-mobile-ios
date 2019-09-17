//
//  Chacha20.swift
//  Bitmark Registry
//
//  Created by Anh Nguyen on 12/6/18.
//  Copyright © 2018 Bitmark Inc. All rights reserved.
//

import Foundation
import Clibsodium

struct Chacha20Poly1305 {

  enum Chacha20Error: Error {
    case cannotEncrypt
    case cannotDecrypt
  }

  static func seal(withKey key: Data, nonce: Data, plainText: Data, additionalData: Data?) throws -> Data {
    let aData = additionalData ?? Data()

    var cipherText = Data(count: plainText.count + Int(16) + aData.count)
    let tmpLength = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)

    let result = cipherText.withUnsafeMutableBytes({ (cipherTextPointer: UnsafeMutableRawBufferPointer) -> Int32 in
      return nonce.withUnsafeBytes({ (noncePointer: UnsafeRawBufferPointer) -> Int32 in
        return key.withUnsafeBytes({ (keyPointer: UnsafeRawBufferPointer) -> Int32 in
          return plainText.withUnsafeBytes({ (plainTextPointer: UnsafeRawBufferPointer) -> Int32 in
            return aData.withUnsafeBytes({ (aPointer: UnsafeRawBufferPointer) -> Int32 in
              return Clibsodium.crypto_aead_chacha20poly1305_ietf_encrypt(cipherTextPointer.bindMemory(to: UInt8.self).baseAddress,
                                                                          tmpLength,
                                                                          plainTextPointer.bindMemory(to: UInt8.self).baseAddress,
                                                                          UInt64(plainText.count),
                                                                          aPointer.bindMemory(to: UInt8.self).baseAddress,
                                                                          UInt64(aData.count),
                                                                          nil,
                                                                          noncePointer.bindMemory(to: UInt8.self).baseAddress,
                                                                          keyPointer.bindMemory(to: UInt8.self).baseAddress)
            })
          })
        })
      })
    })

    if result != 0 {
      throw Chacha20Error.cannotEncrypt
    }

    return cipherText
  }

  static func open(withKey key: Data, nonce: Data, cipherText: Data, additionalData: Data?) throws -> Data {

    let aData = additionalData ?? Data()
    var plainText = Data(count: cipherText.count - Int(crypto_aead_chacha20poly1305_IETF_ABYTES) - aData.count)
    let tmpLength = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)

    let result = plainText.withUnsafeMutableBytes({ (plainTextPointer: UnsafeMutableRawBufferPointer) -> Int32 in
      return nonce.withUnsafeBytes({ (noncePointer: UnsafeRawBufferPointer) -> Int32 in
        return key.withUnsafeBytes({ (keyPointer: UnsafeRawBufferPointer) -> Int32 in
          return cipherText.withUnsafeBytes({ (cipherTextPointer: UnsafeRawBufferPointer) -> Int32 in
            return aData.withUnsafeBytes({ (aPointer: UnsafeRawBufferPointer) -> Int32 in
              return Clibsodium.crypto_aead_chacha20poly1305_ietf_decrypt(plainTextPointer.bindMemory(to: UInt8.self).baseAddress,
                                                                          tmpLength,
                                                                          nil,
                                                                          cipherTextPointer.bindMemory(to: UInt8.self).baseAddress,
                                                                          UInt64(cipherText.count),
                                                                          aPointer.bindMemory(to: UInt8.self).baseAddress,
                                                                          UInt64(aData.count),
                                                                          noncePointer.bindMemory(to: UInt8.self).baseAddress,
                                                                          keyPointer.bindMemory(to: UInt8.self).baseAddress)
            })
          })
        })
      })
    })

    if result != 0 {
      throw Chacha20Error.cannotEncrypt
    }

    return plainText
  }
}
