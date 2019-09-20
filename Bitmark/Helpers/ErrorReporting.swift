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
      Client.shared?.user = User(userId: userId)
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
    let errorEvent = Event(level: .error)
    let errMessage = err is String ? (err as? String) : err.localizedDescription
    errorEvent.message = errMessage ?? ""
    Client.shared?.appendStacktrace(to: errorEvent)
    Client.shared?.send(event: errorEvent, completion: nil)
  }

  public static func report(message: String) {
    let errorEvent = Event(level: .error)
    errorEvent.message = message
    Client.shared?.appendStacktrace(to: errorEvent)
    Client.shared?.send(event: errorEvent, completion: nil)
  }

  // Log info to sentry
  public static func breadcrumbs(info msg: String, category: ReportCategory, traceLog: Bool = true) {
    let breadcrumb = Breadcrumb(level: .info, category: category.rawValue)
    breadcrumb.message = msg
    Client.shared?.breadcrumbs.add(breadcrumb)

    if traceLog { Global.log.info(msg) }
  }
}

enum ReportCategory: String {
  case bitmarkSDK, APNS, intercom, fileCourier, ownershipApprovance
  case storeFile, migrationData, transferFile, updateAccessFile, uploadFile, downloadFile, storeData
  case keychain, warningError, dbData
  case account, accountKey, bitmark
}

open class SentryDestination: BaseDestination {
  private let client: Client
  private let logQueue: DispatchQueue?
  
  public init(sentryClient: Client, queue: DispatchQueue? = nil) {
    self.client = sentryClient
    self.logQueue = queue
    super.init()
  }
  
  open override func output(logDetails: LogDetails, message: String) {
    let outputClosure = { [weak self] in
      guard let self = self,
      self.isEnabledFor(level: logDetails.level) else { return }
        
      var sentryLevel: SentrySeverity
      switch logDetails.level {
      case .debug:
        sentryLevel = .debug
      case .info:
        sentryLevel = .info
      case .warning:
        sentryLevel = .warning
      case .severe:
        sentryLevel = .fatal
      case .error:
        sentryLevel = .error
      default:
        return
      }
      
      let filename = logDetails.fileName.deletingPathExtension.lastPathComponent
        
      if sentryLevel == .error || sentryLevel == .fatal || sentryLevel == .warning {
        let errorEvent = Event(level: sentryLevel)
        errorEvent.message = logDetails.message
        errorEvent.tags = ["filename": filename,
                           "function": logDetails.functionName]
        errorEvent.extra = logDetails.userInfo
        self.client.appendStacktrace(to: errorEvent)
        self.client.send(event: errorEvent, completion: nil)
      } else {
        let breadcrumb = Breadcrumb(level: sentryLevel, category: filename)
        breadcrumb.message = "[\(logDetails.functionName):\(logDetails.lineNumber)] \(logDetails.message)"
        breadcrumb.data = logDetails.userInfo
        self.client.breadcrumbs.add(breadcrumb)
      }
    }

    if let logQueue = logQueue {
      logQueue.async(execute: outputClosure)
    } else {
      outputClosure()
    }
  }
}
