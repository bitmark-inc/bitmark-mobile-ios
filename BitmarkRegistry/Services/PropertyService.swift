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
    var issueParams = try Bitmark.newIssuanceParams(assetID: assetId, owner: issuer.getAccountNumber(), quantity: quantity)
    try issueParams.sign(issuer)
    return try Bitmark.issue(issueParams)
  }

  static func listAllAssets(registrant: Account) throws -> [Asset] {
    let params = try Asset.newQueryParams()
                          .limit(size: 100)
                          .registeredBy(registrant: "eeUqCy12biXVd8PDcYkKXR7nSJh7A5tHsPKhJWJB45v499VQTT")
                          .pending(true)
    return try Asset.list(params: params)
  }

  static func listIssurance() {
  }
}
