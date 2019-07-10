//
//  AssetService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/14/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class AssetService {

  static func getFingerprintFrom(_ data: Data) -> String {
    return FileUtil.computeFingerprint(data: data)
  }

  static func getAsset(from fingerprint: String) -> Asset? {
    guard let assetId = computeAssetId(fingerprint: fingerprint) else { return nil }

    do {
      return try Asset.get(assetID: assetId)
    } catch {
      return nil
    }
  }

  typealias AssetInfo = (registrant: Account, assetName: String, fingerprint: Data, metadata: [String: String])
  static func registerProperty(assetInfo: AssetInfo, quantity: Int) throws -> String {
    let assetId = try AssetService.registerAsset(
      registrant: assetInfo.registrant,
      assetName: assetInfo.assetName,
      fingerprint: assetInfo.fingerprint,
      metadata: assetInfo.metadata
    )

    _ = try AssetService.issueBitmarks(
      issuer: assetInfo.registrant,
      assetId: assetId,
      quantity: quantity
    )

    return assetId
  }

  static func registerAsset(registrant: Account, assetName: String, fingerprint: Data, metadata: [String: String]) throws -> String {
    var assetParams = try Asset.newRegistrationParams(name: assetName, metadata: metadata)
    try assetParams.setFingerprint(fromData: fingerprint)
    try assetParams.sign(registrant)
    return try Asset.register(assetParams)
  }

  static func issueBitmarks(issuer: Account, assetId: String, quantity: Int) throws {
    var issueParams = try Bitmark.newIssuanceParams(assetID: assetId, quantity: quantity)
    try issueParams.sign(issuer)
    try Bitmark.issue(issueParams)
  }

  // Reference from BitmarkSDK
  fileprivate static func computeAssetId(fingerprint: String) -> String? {
    guard let fingerprintData = fingerprint.data(using: .utf8) else {
      return nil
    }
    return fingerprintData.sha3(length: 512).hexEncodedString
  }
}
