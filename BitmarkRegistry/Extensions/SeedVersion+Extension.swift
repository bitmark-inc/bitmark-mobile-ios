//
//  SeedVersion+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/25/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
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
}
