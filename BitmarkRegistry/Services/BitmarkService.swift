//
//  BitmarkService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/16/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

class BitmarkService {

  static func listAllBitmarksWithAsset(owner: Account, at fromOffset: Int64, direction: QueryDirection) throws -> ([Bitmark], [Asset]) {
    let params = try Bitmark.newBitmarkQueryParams()
                            .loadAsset(true)
                            .limit(size: 100)
                            .ownedByWithTransient(owner.getAccountNumber())
                            .at(fromOffset)
                            .to(direction: direction)
                            .pending(true)
    let (bitmarks, assets) = try Bitmark.list(params: params)
    return (bitmarks ?? [Bitmark](), assets ?? [Asset]())
  }

  static func directTransfer(account: Account, bitmarkId: String, to receiverAccountNumber: String) throws -> String {
    ErrorReporting.breadcrumbs(info: "direct transfer bitmark", category: .bitmark)
    defer { ErrorReporting.breadcrumbs(info: "finished direct transferring bitmark", category: .bitmark) }

    var transferParams = try Bitmark.newTransferParams(to: receiverAccountNumber)
    try transferParams.from(bitmarkID: bitmarkId)
    try transferParams.sign(account)

    return try Bitmark.transfer(withTransferParams: transferParams)
  }
}
