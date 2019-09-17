//
//  SeedVersion+Extension.swift
//  Bitmark
//
//  Created by Thuyen Truong on 7/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK

extension SeedVersion {

  init?(numberOfPhrases: Int) {
    if numberOfPhrases == 24 {
      self = .v1
    } else if numberOfPhrases == 12 {
      self = .v2
    } else {
      return nil
    }
  }

  init?(versionString: String) {
    switch versionString {
    case "v1":
      self = .v1
    case "v2":
      self = .v2
    default:
      return nil
    }
  }

  func stringFromVersion() -> String {
    switch self {
    case .v1:
      return "v1"
    case .v2:
      return "v2"
    }
  }
}
