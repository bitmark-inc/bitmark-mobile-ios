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

  static func getAsset(from fingerprint: String) -> AssetR? {
    guard let assetId = RegistrationParams.computeAssetId(fingerprint: fingerprint) else { return nil }

    do {
      let userRealm = try RealmConfig.currentRealm()
      if let assetR = userRealm?.object(ofType: AssetR.self, forPrimaryKey: assetId) {
        return assetR
      }
    } catch {
      ErrorReporting.report(error: error)
    }

    do {
      let asset = try Asset.get(assetID: assetId)
      return AssetR(asset: asset)
    } catch {
      return nil
    }
  }

  typealias AssetInfo = (registrant: Account, assetName: String, fingerprint: String, metadata: [String: String])
  static func registerAsset(assetInfo: AssetInfo) throws -> String {
    ErrorReporting.breadcrumbs(info: "register asset", category: .bitmark)
    defer { ErrorReporting.breadcrumbs(info: "finished registering asset", category: .bitmark) }

    var assetParams = try Asset.newRegistrationParams(name: assetInfo.assetName, metadata: assetInfo.metadata)
    try assetParams.setFingerprint(assetInfo.fingerprint)
    try assetParams.sign(assetInfo.registrant)
    return try Asset.register(assetParams)
  }

  static func issueBitmarks(issuer: Account, assetId: String, quantity: Int) throws {
    ErrorReporting.breadcrumbs(info: "issue bitmark", category: .bitmark)
    defer { ErrorReporting.breadcrumbs(info: "finished issuing bitmark", category: .bitmark) }

    var issueParams = try Bitmark.newIssuanceParams(assetID: assetId, quantity: quantity)
    try issueParams.sign(issuer)
    _ = try Bitmark.issue(issueParams)
  }
}
