//
//  AssetService.swift
//  Bitmark
//
//  Created by Thuyen Truong on 6/14/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK

class AssetService {

  static func getAsset(_ assetId: String) -> Asset? {
    do {
      return try Asset.get(assetID: assetId)
    } catch {
      return nil
    }
  }

  typealias AssetInfo = (registrant: Account, assetName: String, fingerprint: String, metadata: [String: String])
  static func registerAsset(assetInfo: AssetInfo) throws -> String {
    Global.log.info("register asset")
    defer { Global.log.info("finished registering asset") }

    var assetParams = try Asset.newRegistrationParams(name: assetInfo.assetName, metadata: assetInfo.metadata)
    try assetParams.setFingerprint(assetInfo.fingerprint)
    try assetParams.sign(assetInfo.registrant)
    return try Asset.register(assetParams)
  }

  static func issueBitmarks(issuer: Account, assetId: String, quantity: Int) throws {
    Global.log.info("issue bitmark")
    defer { Global.log.info("finished issuing bitmark") }

    var issueParams = try Bitmark.newIssuanceParams(assetID: assetId, quantity: quantity)
    try issueParams.sign(issuer)
    _ = try Bitmark.issue(issueParams)
  }
}
