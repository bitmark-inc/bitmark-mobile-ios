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

/*
 Idea: Route to specific screen from any screen.
 This serves for deep link and notification purpose.
 */
class ScreenRouteService {
  
  // Return true if successful landing
  typealias RouteCompletionHandler = (Bool) -> Void
  
  // Route to bitmark detail screen
  static func routeToBitmarkDetail(bitmarkID: String, completionHandler: RouteCompletionHandler?) {
    guard let tabbarController = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController else {
      completionHandler?(false)
      return
    }
    
    guard let currentAccount = Global.currentAccount else {
      completionHandler?(false)
      return
    }
    
    // Select first tab
    tabbarController.selectedIndex = 0
    
    // Detect root view controller
    guard let navigationController = tabbarController.viewControllers?[0] as? UINavigationController else {
      completionHandler?(false)
      return
    }
    
    do {
      let userConfiguration = try RealmConfig.user(currentAccount.getAccountNumber()).configuration()
      let realm = try Realm(configuration: userConfiguration)
      let bitmarkR = realm.object(ofType: BitmarkR.self, forPrimaryKey: bitmarkID)
      
      // Init bitmark detail view controller
      let bitmarkDetailsVC = BitmarkDetailViewController()
      bitmarkDetailsVC.bitmarkR = bitmarkR
      bitmarkDetailsVC.assetR = bitmarkR?.assetR
      bitmarkDetailsVC.hidesBottomBarWhenPushed = true
      
      // Replace entire view controller stack with new one
      navigationController.setViewControllers([navigationController.viewControllers.first!,
                                               bitmarkDetailsVC], animated: true)
      
      completionHandler?(true)
    } catch let e {
      ErrorReporting.report(error: e)
      completionHandler?(false)
    }
  }
  
}
