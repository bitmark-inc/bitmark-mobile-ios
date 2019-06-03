//
//  PropertyService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/31/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class PropertyService {

  static func getFingerprintFrom(_ data: Data) -> String {
    return FileUtil.computeFingerprint(data: data)
  }

  static func registerAsset(registrant: Account, assetName: String, fingerprint: Data, metadata: [String:String]) throws -> String {
    var assetParams = try Asset.newRegistrationParams(name: assetName, metadata: metadata)
    try assetParams.setFingerprint(fromData: fingerprint)
    try assetParams.sign(registrant)
    return try Asset.register(assetParams)
  }

  static func issueBitmarks(issuer: Account, assetId: String, quantity: Int) throws -> [String] {
    var issueParams = try Bitmark.newIssuanceParams(assetID: assetId, owner: issuer.accountNumber, quantity: quantity)
    try issueParams.sign(issuer)
    return try Bitmark.issue(issueParams)
  }
}
