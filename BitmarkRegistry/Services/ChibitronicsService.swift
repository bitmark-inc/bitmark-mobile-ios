//
//  ChibitronicsService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/1/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

struct ChibitronicsService {

  let qrCodeRegex = "(\\w+ ){5}\\w+\\|https?://.+"
  let qrCode: String
  var code: String!
  var url: URL!

  init(qrCode: String) {
    self.qrCode = qrCode
  }

  func isValidQrCode() -> Bool {
    return qrCode.range(of: qrCodeRegex, options: .regularExpression, range: nil, locale: nil) != nil
  }

  mutating func extractData() -> (code: String, url: URL)? {
    let qrCodeParts = qrCode.split(separator: "|")
    if let url = URL(string: String(qrCodeParts[1])) {
      self.code = String(qrCodeParts[0])
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
    ErrorReporting.breadcrumbs(info: infoLog, category: "Chibitronics")
    Global.log.info(infoLog)

    let params: [String : String] = [
      "bitmark_account": account.getAccountNumber(),
      "code": code,
      "signature": signature.hexEncodedString
    ]
    let jsonData = try JSONSerialization.data(withJSONObject: params)

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
