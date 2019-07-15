//
//  Global.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK
import XCGLogger
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
  static var currentAssets = [Asset]()
  static var currentBlocks = [Block]()
  static var latestOffset: [String: Int64] = [:]
  static var noInternetBanner: NotificationBanner = {
    return NotificationBanner(title: "", subtitle: "NO INTERNET CONNECTION", style: .danger, colors: CustomBannerColors())
  }()

  public static func clearData() {
    currentAccount = nil
    currentJwt = nil
    currentAssets.removeAll()
    latestOffset = [:]
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

    return log
  }()

  static func appError(errorCode: Int, message: String) -> NSError {
    let hostDomain = "come.bitmark.registry"
    let hostErrorCode = errorCode

    return NSError(domain: hostDomain, code: hostErrorCode, userInfo: [NSLocalizedDescriptionKey: message])
  }

  public struct ServerURL {
    public static let mobile = Credential.valueForKey(keyName: Constant.InfoKey.mobileServerURL)
    public static let keyAccountAsset = Credential.valueForKey(keyName: Constant.InfoKey.keyAccountAssetServerURL)
    public static let fileCourier = Credential.valueForKey(keyName: Constant.InfoKey.fileCourierServerURL)
    public static let registry = Credential.valueForKey(keyName: Constant.InfoKey.registryServerURL)
  }
}

// MARK: - Support Functions
extension Global {
  public static func addAssets(_ assets: [Asset]) {
    currentAssets += assets
  }

  public static func findAsset(with assetId: String) -> Asset? {
    return currentAssets.last(where: { $0.id == assetId })
  }

  public static func addBlocks(_ blocks: [Block]) {
    currentBlocks += blocks
  }

  public static func findBlock(with blockId: Int64) -> Block? {
    return currentBlocks.last(where: { $0.number == blockId })
  }
}

extension Global {
  static func showNoInternetBanner() {
    noInternetBanner.show()
    noInternetBanner.applyStyling(subtitleFont: UIFont(name: "Avenir-Black", size: 16), subtitleTextAlign: .center)
  }

  static func hideNoInternetBanner() {
    noInternetBanner.dismiss()
  }

  public class CustomBannerColors: BannerColorsProtocol {
    public func color(for style: BannerStyle) -> UIColor {
      switch style {
      case .danger:   return UIColor.mainRedColor
      case .info:     return UIColor(red:0.23, green:0.60, blue:0.85, alpha:1.00)
      case .none:     return UIColor.clear
      case .success:  return UIColor(red:0.22, green:0.80, blue:0.46, alpha:1.00)
      case .warning:  return UIColor(red:1.00, green:0.66, blue:0.16, alpha:1.00)
      }
    }
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

extension Global {
  static func rxCurrentAccount() -> Observable<Account> {
    return Observable<Account?>.of(self.currentAccount).errorOnNil()
  }
}
