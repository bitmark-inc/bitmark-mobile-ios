//
//  MusicService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/14/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import RxAlamofire

class MusicService {

  // Only support for Pochang Music for now
  static let assetId = "80450f726589fa2acf198ee83b2d040b001b843b11aa245bee55910b5ca6a505c55a2570e57803f8215f9ee7622265a2ecd59c33b8bbbfe1a5551c709604ff70"

  static func assetInfo(assetId: String) -> Observable<ClaimingAssetInfo> {
    let assetInfoURL = URL(string: Global.ServerURL.registry + "/s/api/asset-for-claim?asset_id=" + assetId)!
    let apiRequest = URLRequest(url: assetInfoURL)

    return RxAlamofire.request(apiRequest)
      .debug()
      .responseData()
      .expectingObject(ofType: ClaimingAssetInfo.self)
  }
}
