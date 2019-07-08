//
//  EventDelegate.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/8/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

// Common Event Delegate for PropertiesViewController & TransactionsViewController
protocol EventDelegate: class {
  associatedtype Record
  func receiveNewRecords(_ newRecords: [Record])
  func syncUpdatedRecords()
}
