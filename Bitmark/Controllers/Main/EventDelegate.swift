//
//  EventDelegate.swift
//  Bitmark
//
//  Created by Thuyen Truong on 7/8/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK

// Common Event Delegate for PropertiesViewController & TransactionsViewController
protocol EventDelegate: class {
  func setupBitmarkEventSubscription()
  func syncUpdatedRecords()
}

extension EventDelegate {
  func setupBitmarkEventSubscription() {
    do {
      let eventSubscription = EventSubscription.shared
      try eventSubscription.connect(Global.currentAccount!)

      try eventSubscription.listenBitmarkPending { [weak self] (_) in
        self?.syncUpdatedRecords()
      }

      try eventSubscription.listenBitmarkChanged { [weak self] (_) in
        self?.syncUpdatedRecords()
      }

      try eventSubscription.listenTxPending { [weak self] (_) in
        self?.syncUpdatedRecords()
      }
    } catch {
      ErrorReporting.report(error: error)
    }
  }
}
