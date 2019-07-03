//
//  ErrorReporting.swift
//  BitmarkRegistry
//
//  Created by Anh Nguyen on 7/2/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import Sentry

// Send error report to Sentry
struct ErrorReporting {
  
  // Set current bitmark account to sentry error report to be informative to debug
  public static func setAccount(bitmarkAccount: String?) {
    if let account = bitmarkAccount {
      Client.shared?.user = User(userId: account)
    } else {
      Client.shared?.user = nil
    }
  }
  
  // Set current env information
  public static func setEnv() {
    if let bundlename = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
      Client.shared?.environment = bundlename == "com.bitmark.registry" ? "production" : "test"
    }
    
    if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
      Client.shared?.dist = appVersion
    }
  }
  
  // Report error to sentry
  public static func report(error err: Error) {
    let e = Event(level: .error)
    e.message = err.localizedDescription
    Client.shared?.send(event: e, completion: nil)
  }
  
  // Log info to sentry
  public static func breadcrumbs(info msg: String, category: String) {
    let b = Breadcrumb(level: .info, category: category)
    b.message = msg
    Client.shared?.breadcrumbs.add(b)
  }
}
