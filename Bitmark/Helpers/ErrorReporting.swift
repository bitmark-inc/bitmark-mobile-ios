//
//  ErrorReporting.swift
//  Bitmark
//
//  Created by Anh Nguyen on 7/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import Sentry
import XCGLogger

// Send error report to Sentry
struct ErrorReporting {

  // Set current bitmark account number to sentry error report to be informative to debug
  // Set nil to remove user from current session
  public static func setUser(bitmarkAccountNumber: String?) {
    if let userId = bitmarkAccountNumber {
        SentrySDK.setUser(User(userId: userId))
    } else {
        SentrySDK.setUser(nil)
    }
  }
}

enum ReportCategory: String {
  case bitmarkSDK, APNS, intercom, fileCourier, ownershipApprovance
  case storeFile, migrationData, transferFile, updateAccessFile, uploadFile, downloadFile, storeData
  case keychain, warningError, dbData
  case account, accountKey, bitmark
}

open class SentryDestination: BaseDestination {
  private let logQueue: DispatchQueue?
  
  public init(queue: DispatchQueue? = nil) {
    self.logQueue = queue
    super.init()
  }
  
  open override func output(logDetails: LogDetails, message: String) {
    let outputClosure = { [weak self] in
      guard let self = self,
      self.isEnabledFor(level: logDetails.level) else { return }
        
      var sentryLevel: SentryLevel
      switch logDetails.level {
      case .debug:
        sentryLevel = .debug
      case .info:
        sentryLevel = .info
      case .warning:
        sentryLevel = .warning
      case .severe:
        sentryLevel = .warning
      case .error:
        sentryLevel = .error
      default:
        return
      }
      
      let filename = logDetails.fileName.deletingPathExtension.lastPathComponent
        
      if sentryLevel == .error || sentryLevel == .fatal || sentryLevel == .warning {
        let errorEvent = Event(level: sentryLevel)
        errorEvent.message = SentryMessage(formatted: logDetails.message)
        errorEvent.tags = ["filename": filename,
                           "function": logDetails.functionName]
        errorEvent.extra = logDetails.userInfo
        SentrySDK.capture(event: errorEvent)
      } else {
        let breadcrumb = Breadcrumb(level: sentryLevel, category: filename)
        breadcrumb.message = "[\(logDetails.functionName):\(logDetails.lineNumber)] \(logDetails.message)"
        breadcrumb.data = logDetails.userInfo
        SentrySDK.addBreadcrumb(crumb: breadcrumb)
      }
    }

    if let logQueue = logQueue {
      logQueue.async(execute: outputClosure)
    } else {
      outputClosure()
    }
  }
}
