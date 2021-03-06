//
//  Credential.swift
//  Bitmark
//
//  Created by Thuyen Truong on 5/29/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

class Credential {
  public static func valueForKey(keyName: String) -> String {
    guard let appCredentials = Bundle.main.object(forInfoDictionaryKey: "AppCredentials") as? [String: String] else { return "" }
    return appCredentials[keyName] ?? ""
  }
}
