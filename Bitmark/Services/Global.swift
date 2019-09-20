//
//  Global.swift
//  Bitmark
//
//  Created by Thuyen Truong on 5/29/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import BitmarkSDK
import XCGLogger
import Sentry
import RxSwift
import NotificationBannerSwift

class Global {

  static var currentAccount: Account? = nil {
    didSet {
      ErrorReporting.setUser(bitmarkAccountNumber: currentAccount?.address)
    }
  }
  static var currentJwt: String?
  static var apnsToken: String? // Push notification token
  static var verificationLink: String? // Chibitronics
  static var isiCloudEnabled: Bool?
  static var noInternetBanner: StatusBarNotificationBanner = {
    let statusBarNotificationBanner = StatusBarNotificationBanner(
      title: "NoInternetConnection".localized(),
      style: .danger, colors: CustomBannerColors()
    )
    statusBarNotificationBanner.applyStyling(titleFont: UIFont(name: "Avenir-Black", size: 12)!)
    return statusBarNotificationBanner
  }()

  public static func clearData() {
    currentAccount = nil
    currentJwt = nil
    isiCloudEnabled = nil
    BitmarkStorage._shared = nil
    TransactionStorage._shared = nil
    AccountDependencyService._shared = nil
    iCloudService._shared = nil
    UserSetting.shared.logUserOut()
  }

  public static func syncNewDataInStorage() {
    guard Global.currentAccount != nil else { return }
    BitmarkStorage.shared().asyncUpdateInSerialQueue(completion: nil)
    TransactionStorage.shared().asyncUpdateInSerialQueue(completion: nil)
  }

  // Global logger
  static let log: XCGLogger = {
    // Create a logger object with no destinations
    let log = XCGLogger(identifier: "bitmark.logger", includeDefaultDestinations: false)

    // Create a destination for the system console log (via NSLog)
    let systemDestination = AppleSystemLogDestination(identifier: "bitmark.logger.syslog")

    // Set some configuration options
    systemDestination.outputLevel = .debug
    systemDestination.showLogIdentifier = false
    systemDestination.showFunctionName = false
    systemDestination.showThreadName = false
    systemDestination.showLevel = true
    systemDestination.showFileName = false
    systemDestination.showLineNumber = false

    // Add the destination to the logger
    log.add(destination: systemDestination)

    // Create a file log destination
    let tmpDirURL = FileManager.default.temporaryDirectory
    let logFileURL = tmpDirURL.appendingPathComponent("app.log")
    print("Write log to: ", logFileURL.absoluteString)
    let fileDestination = AutoRotatingFileDestination(writeToFile: logFileURL, identifier: "bitmark.logger.file", shouldAppend: true)

    // Set some configuration options
    fileDestination.outputLevel = .info
    fileDestination.showLogIdentifier = false
    fileDestination.showFunctionName = true
    fileDestination.showThreadName = true
    fileDestination.showLevel = true
    fileDestination.showFileName = true
    fileDestination.showLineNumber = true
    fileDestination.showDate = true
    fileDestination.targetMaxLogFiles = 250

    // Process this destination in the background
    fileDestination.logQueue = XCGLogger.logQueue

    // Add the destination to the logger
    log.add(destination: fileDestination)
    
    if var sentryClient = try? Client(dsn: Credential.valueForKey(keyName: "SENTRY_DSN")) {
      // Create sentry destination
      sentryClient.environment = Bundle.main.bundleIdentifier
      Client.shared = sentryClient
      
      let sentryDestination = SentryDestination(sentryClient: sentryClient,
                                                queue: DispatchQueue(label: "com.bitmark.ios.sentry", qos: .background))
      sentryDestination.outputLevel = .info
      sentryDestination.showLogIdentifier = false
      sentryDestination.showFunctionName = true
      sentryDestination.showThreadName = true
      sentryDestination.showLevel = true
      sentryDestination.showFileName = true
      sentryDestination.showLineNumber = true
      sentryDestination.showDate = true
      log.add(destination: sentryDestination)
    }
    
    return log
  }()

  static func appError(errorCode: Int = 400, message: String) -> NSError {
    let hostDomain = "come.bitmark.registry"
    let hostErrorCode = errorCode

    return NSError(domain: hostDomain, code: hostErrorCode, userInfo: [NSLocalizedDescriptionKey: message])
  }

  public struct ServerURL {
    public static let bitmark = "https://bitmark.com"
    public static let mobile = Credential.valueForKey(keyName: Constant.InfoKey.mobileServerURL)
    public static let keyAccountAsset = Credential.valueForKey(keyName: Constant.InfoKey.keyAccountAssetServerURL)
    public static let fileCourier = Credential.valueForKey(keyName: Constant.InfoKey.fileCourierServerURL)
    public static let registry = Credential.valueForKey(keyName: Constant.InfoKey.registryServerURL)
    public static let profiles = Credential.valueForKey(keyName: Constant.InfoKey.profilesServerURL)
  }
}

// MARK: - Support Functions
extension Global {
  static func showNoInternetBanner() {
    noInternetBanner.show()
  }

  static func hideNoInternetBanner() {
    noInternetBanner.dismiss()
  }
}

enum BitmarkStatus: String {
  case settled
  case issuing
  case transferring
}

enum TransactionStatus: String {
  case confirmed
  case pending
}

enum ClaimRequestStatus: String {
  case accepted
  case rejected
}

enum FieldState {
  case `default`, success, error, focus
}

extension Global {
  static func rxCurrentAccount() -> Observable<Account> {
    return Observable<Account?>.of(self.currentAccount).errorOnNil()
  }
}
