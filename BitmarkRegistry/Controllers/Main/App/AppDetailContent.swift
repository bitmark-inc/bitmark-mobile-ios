//
//  AppDetailContent.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/12/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

enum AppDetailContent {
  case termsOfService
  case privacyPolicy

  func title() -> String {
    switch self {
    case .termsOfService:
      return "TERMS OF SERVICE"
    case .privacyPolicy:
      return "PRIVACY POLICY"
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
