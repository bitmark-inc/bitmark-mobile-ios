//
//  NotificationBanner+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/28/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import NotificationBannerSwift

public class CustomBannerColors: BannerColorsProtocol {
  public func color(for style: BannerStyle) -> UIColor {
    switch style {
    case .danger:   return UIColor.mainRedColor
    case .info:     return UIColor(red:0.23, green:0.60, blue:0.85, alpha:1.00)
    case .customView:     return UIColor.clear
    case .success:  return UIColor(red:0.22, green:0.80, blue:0.46, alpha:1.00)
    case .warning:  return UIColor(red:1.00, green:0.66, blue:0.16, alpha:1.00)
    }
  }
}

public extension StatusBarNotificationBanner {
  func applyStyling(titleFont: UIFont) {
    titleLabel?.font = titleFont
  }
}
