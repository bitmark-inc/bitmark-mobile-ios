//
//  AssetService.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 6/14/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK

class AssetService {

  static func getFingerprintFrom(_ data: Data) -> String {
    return FileUtil.computeFingerprint(data: data)
  }

  static func getAsset(from fingerprint: String) -> AssetR? {
    guard let assetId = computeAssetId(fingerprint: fingerprint) else { return nil }

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

  typealias AssetInfo = (registrant: Account, assetName: String, fingerprint: Data, metadata: [String: String])
  static func registerAsset(assetInfo: AssetInfo) throws -> String {
    var assetParams = try Asset.newRegistrationParams(name: assetInfo.assetName, metadata: assetInfo.metadata)
    try assetParams.setFingerprint(fromData: assetInfo.fingerprint)
    try assetParams.sign(assetInfo.registrant)
    return try Asset.register(assetParams)
  }

  static func issueBitmarks(issuer: Account, assetId: String, quantity: Int) throws {
    var issueParams = try Bitmark.newIssuanceParams(assetID: assetId, quantity: quantity)
    try issueParams.sign(issuer)
    _ = try Bitmark.issue(issueParams)
  }

  // Reference from BitmarkSDK
  fileprivate static func computeAssetId(fingerprint: String) -> String? {
    guard let fingerprintData = fingerprint.data(using: .utf8) else {
      return nil
    }
    return fingerprintData.sha3(length: 512).hexEncodedString
  }
}
