//
//  BitmarkService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class BitmarkSDKService {

  private static let networkMode: Network = {
    #if PRODUCTION
      return Network.livenet
    #else
      return Network.testnet
    #endif
  }()
  static let apiToken = Credential.valueForKey(keyName: "BITMARK_API_TOKEN")

  static func setupConfig() {
    let config = SDKConfig(apiToken: apiToken, network: networkMode, urlSession: URLSession.shared)
    BitmarkSDK.initialize(config: config)
  }
}
