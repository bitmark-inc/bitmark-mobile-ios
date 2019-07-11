//
//  ReachabilityManager.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/10/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import Reachability

struct NetworkManager {

  static let shared = NetworkManager()
  let reachability: Reachability!

  init() {
    reachability = Reachability()!
  }

  static func isReachable() -> Bool {
    return NetworkManager.shared.reachability.connection != .none
  }

  static func startNotifier(completion: @escaping () -> Void) {
    NetworkManager.shared.reachability.whenReachable = { reachability in
      completion()
      stopNotifier()
    }

    do {
      try NetworkManager.shared.reachability.startNotifier()
    } catch {
      ErrorReporting.report(error: error)
      return
    }
  }

  static func stopNotifier() -> Void {
    NetworkManager.shared.reachability.stopNotifier()
  }
}

