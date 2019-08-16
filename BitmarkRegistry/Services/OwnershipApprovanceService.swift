//
//  ChibitronicsService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/1/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

enum VerificationLinkSource {
  case qrCode, deepLink
}

class OwnershipApprovanceService {

  let verificationLink: String
  let source: VerificationLinkSource
  lazy var separator: Character = { source == .qrCode ? "|" : "/" }()
  lazy var regex: String = { "(\\w+ ){5}\\w+\\\(separator)https?://.+" }()

  var code: String!
  var url: URL!

  init(verificationLink: String, source: VerificationLinkSource) {
    self.verificationLink = verificationLink
    self.source = source
  }

  func isValid() -> Bool {
    return verificationLink.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
  }

  func extractData() -> (code: String, url: URL)? {
    let codeParts = verificationLink.split(separator: separator, maxSplits: 1)

    if let url = URL(string: String(codeParts[1])) {
      self.code = String(codeParts[0])
      self.url = url
      return (code: code, url: url)
    } else {
      return nil
    }
  }

  func requestAuthorization(for account: Account, completion: @escaping (Error?) -> Void) throws {
    guard let url = url, let code = code else { return }
    let message = "Verify|\(code)"
    let signature = try account.sign(message: message.data(using: .utf8)!)

    let infoLog = "requestAuthorization for account: \(account.getAccountNumber()); code: \(code)"
    ErrorReporting.breadcrumbs(info: infoLog, category: .OwnershipApprovance)
    Global.log.info(infoLog)

    let params: [String : String] = [
      "bitmark_account": account.getAccountNumber(),
      "code": code,
      "signature": signature.hexEncodedString
    ]
    let jsonData = try JSONEncoder().encode(params)

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.allHTTPHeaderFields = [
      "Accept": "application/json",
      "Content-Type": "application/json"
    ]
    request.httpBody = jsonData

    URLSession.shared.dataTask(with: request) { (data, response, error) in
      if let error = error {
        completion(error)
        return
      }
      completion(nil)
    }.resume()
  }
}
