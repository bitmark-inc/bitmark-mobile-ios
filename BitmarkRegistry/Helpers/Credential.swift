//
//  Credential.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

class Credential {

  public static func valueForKey(keyName:String) -> String {
    if let filePath = Bundle.main.path(forResource: "keys", ofType: "plist"),
      let plist = NSDictionary(contentsOfFile: filePath) {
      return plist.value(forKey: keyName) as! String
    }
    return ""
  }
}
