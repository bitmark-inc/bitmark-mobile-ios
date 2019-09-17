//
//  URLRequest+JWT.swift
//  BitmarkRegistry
//
//  Created by Anh Nguyen on 7/10/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

extension URLRequest {
  mutating func attachAuth() throws {
    guard let jwt = Global.currentJwt else {
      throw("Not logged in yet")
    }

    self.setValue("Bearer " + jwt, forHTTPHeaderField: "Authorization")
  }
}
