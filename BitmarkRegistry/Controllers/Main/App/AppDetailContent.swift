//
//  AppDetailContent.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 7/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation

enum AppDetailContent: String {
  case termsOfService
  case privacyPolicy

  func title() -> String {
    switch self {
    case .termsOfService:
      return "TermsOfService".localized().localizedUppercase
    case .privacyPolicy:
      return "PrivacyPolicy".localized().localizedUppercase
    }
  }

  func contentLink() -> String {
    switch self {
    case .termsOfService:
      return Global.ServerURL.bitmark + "/legal/terms"
    case .privacyPolicy:
      return Global.ServerURL.bitmark + "/legal/privacy"
    }
  }
}
