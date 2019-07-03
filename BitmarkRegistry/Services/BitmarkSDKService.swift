//
//  BitmarkService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK
import XCGLogger

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
    let config = SDKConfig(apiToken: apiToken, network: networkMode, urlSession: URLSession.shared, logger: BitmarkSDKServiceLogger())
    BitmarkSDK.initialize(config: config)
    
  }
}

class BitmarkSDKServiceLogger: SDKLogger {
  func log(level: SDKLogLevel, message: String) {
    Global.log.logln(message,
                     level: sdkToAppLogLevel(level),
                     functionName: "",
                     fileName: "",
                     lineNumber: 0,
                     userInfo: ["Source": "BitmarkSDK"])
    
    if level == .error {
      ErrorReporting.report(error: message)
    } else {
      ErrorReporting.breadcrumbs(info: message, category: "BitmarkSDK")
    }
  }
  
  private func sdkToAppLogLevel(_ sdkLevel: SDKLogLevel) -> XCGLogger.Level {
    switch sdkLevel {
    case .debug:
      return .debug
    case .info:
      return .info
    case .warn:
      return .warning
    case .error:
      return .error
    }
  }
}
