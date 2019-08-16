//
//  ClaimingAsset.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/15/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

struct ClaimingAssetInfo: Decodable {
  let issuer: String
  let limitedEdition: Int
  let totalEditionLeft: Int
}
