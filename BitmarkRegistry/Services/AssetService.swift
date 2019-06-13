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
}
