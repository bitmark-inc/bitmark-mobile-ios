//
//  ClaimRequest.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/15/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

struct ClaimRequests: Codable {
  let claim_requests: [ClaimRequest]
  let my_submitted_claim_requests : [ClaimRequest]
}

struct ClaimRequest: Codable {
  let id: String
  let asset_id: String
  let from: String
  let status: String
  let info: ClaimRequestInfo
  let created_at: Date

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(String.self, forKey: .id)
    asset_id = try values.decode(String.self, forKey: .asset_id)
    from = try values.decode(String.self, forKey: .from)
    status = try values.decode(String.self, forKey: .status)
    info = try values.decode(ClaimRequestInfo.self, forKey: .info)

    let dateFormat =  DateFormatter()
    dateFormat.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
    dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
    let createdAtStr = try values.decode(String.self, forKey: .created_at)
    created_at = dateFormat.date(from: createdAtStr) ?? Date()
  }
}

struct ClaimRequestInfo: Codable {
  let bitmark_id: String
}
