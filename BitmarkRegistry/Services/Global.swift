//
//  Global.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class Global {
  static var currentAccount: Account? = nil
  static var currentAssets = [Asset]()
  static var storedOffsets = [Int64]()

  public static func addAssets(_ assets: [Asset]) {
    currentAssets += assets
  }

  public static func findAsset(with assetId: String) -> Asset? {
    return currentAssets.last(where: { $0.id == assetId })
  }
}
