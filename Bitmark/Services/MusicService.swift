//
//  MusicService.swift
//  Bitmark
//
//  Created by Thuyen Truong on 8/14/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
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

  static func assetThumbnail(assetId: String) -> Observable<UIImage?> {
    let url = URL(string: Global.ServerURL.profiles + "/s/asset/thumbnail?asset_id=" + assetId)!
    return requestData(.get, url)
      .flatMap({ (responseData) -> Observable<UIImage?> in
        return Observable.just(UIImage(data: responseData.1))
      })
  }

  static func listAllClaimRequests() -> Observable<[ClaimRequest]> {
    let url = URL(string: Global.ServerURL.mobile + "/api/claim_requests?asset_id=" + assetId)!
    var apiRequest = URLRequest(url: url)

    do {
      try apiRequest.attachAuth()
    } catch {
      return Observable.error(error)
    }

    return RxAlamofire.request(apiRequest)
      .debug()
      .responseData()
      .expectingObject(ofType: ClaimRequests.self)
      .flatMap({ (data) -> Observable<[ClaimRequest]> in
        return Observable.just(data.my_submitted_claim_requests)
      })
  }
}
