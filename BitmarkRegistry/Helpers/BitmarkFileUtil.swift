//
//  FileUtil.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/28/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class BitmarkFileUtil {
  static func encryptFile(fileURL: URL, destinationURL: URL, sender: Account, receiverPublicKey: Data) throws -> (senderSessionData: SessionData, receiverSessionData: SessionData) {
    let data = try Data(contentsOf: fileURL)
    let assetEncryption = AssetEncryption()
    let encryptedData = try assetEncryption.encryptData(data)
    try encryptedData.write(to: destinationURL)

    let senderSessionData = try assetEncryption.getSessionData(sender: sender, receiverPublicKey: sender.publicKey)
    let receiverSessionData = try assetEncryption.getSessionData(sender: sender, receiverPublicKey: receiverPublicKey)
    return (senderSessionData, receiverSessionData)
  }
}
