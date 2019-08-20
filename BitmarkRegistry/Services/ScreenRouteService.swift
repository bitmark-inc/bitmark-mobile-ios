//
//  ScreenRouteService.swift
//  BitmarkRegistry
//
//  Created by Anh Nguyen on 8/13/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift
import RxFlow
import RxCocoa

/*
 Idea: Route to specific screen from any screen.
 This serves for deep link and notification purpose.
 */
class ScreenRouteService {
  
  // Return true if successful landing
  typealias RouteCompletionHandler = (Bool) -> Void
  
  // Route to bitmark detail screen
  static func routeToBitmarkDetail(bitmarkID: String, completionHandler: RouteCompletionHandler?) {
    guard Global.currentAccount != nil, let _ = routeToPropertiesVC() else {
      completionHandler?(false)
      return
    }

    do {
      let currentRealm = try RealmConfig.currentRealm()

      guard let bitmarkR = currentRealm?.object(ofType: BitmarkR.self, forPrimaryKey: bitmarkID),
            let assetR = bitmarkR.assetR else {
        completionHandler?(false)
        return
      }

      PropertiesStepper.shared.goToBitmarkDetailsScreen(bitmarkR: bitmarkR, assetR: assetR)
      completionHandler?(true)
    } catch let e {
      ErrorReporting.report(error: e)
      completionHandler?(false)
    }
  }

  static func routeToPropertiesVC() -> PropertiesViewController? {
    guard let window = UIApplication.shared.keyWindow else { return nil }

    guard let rootNavigationController = window.rootViewController as? UINavigationController,
       let tabBarVC = rootNavigationController.viewControllers.last as? UITabBarController else { return nil }

    // Select first tab - properties tab
    tabBarVC.selectedIndex = 0

    guard let propertiesFlowRootVC = tabBarVC.selectedViewController as? UINavigationController else { return nil }
    return propertiesFlowRootVC.viewControllers.first as? PropertiesViewController
  }
}
