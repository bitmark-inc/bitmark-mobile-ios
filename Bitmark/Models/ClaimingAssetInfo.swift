//
//  ClaimingAsset.swift
//  Bitmark
//
//  Created by Thuyen Truong on 8/15/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

struct ClaimingAssetInfo: Decodable {
  let issuer: String
  let limitedEdition: Int
  let totalEditionLeft: Int
}
