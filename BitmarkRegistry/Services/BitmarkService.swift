//
//  BitmarkService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class BitmarkService {

  private static let networkMode = Network.testnet;
  private static let apiToken = Credential.valueForKey(keyName: "BITMARK_API_TOKEN")

  static func initialize() {
    let config = SDKConfig(apiToken: apiToken, network: networkMode, urlSession: URLSession.shared)
    BitmarkSDK.initialize(config: config)
  }
}
