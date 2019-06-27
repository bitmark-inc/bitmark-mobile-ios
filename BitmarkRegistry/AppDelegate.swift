//
//  AppDelegate.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var retryAuthenticationAlert: UIAlertController?


  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // init BitmarkSDK environment & api_token
    BitmarkSDKService.setupConfig()

    window = UIWindow(frame: UIScreen.main.bounds)
    window?.makeKeyAndVisible()

    // Redirect Screen for new user / existing user
    let initialVC = AccountService.existsCurrentAccount()
                          ? CustomTabBarViewController()
                          : OnboardingViewController()
    window?.rootViewController = initialVC

    evaluatePolicyWhenUserSetEnable()

    return true
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  /**
   - evaluate Touch/Face ID if user set enabled
   - sync new Bitmarks to display in Properties list (cause in background, app tempoarily stop listening event subscription)
   */
  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    evaluatePolicyWhenUserSetEnable()
    if Global.currentAccount != nil {
      BitmarkStorage.shared().asyncSerialMoreBitmarks(notifyNew: true, completion: nil)
    }
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

private extension AppDelegate {
  func evaluatePolicyWhenUserSetEnable() {
    guard Global.currentAccount != nil else { return }
    guard UserSetting.shared.getTouchFaceIdSetting() else { return }
    retryAuthenticationAlert?.dismiss(animated: false, completion: nil)

    BiometricAuth().authorizeAccess { [weak self] (errorMessage) in
      guard let self = self else { return }
      if let errorMessage = errorMessage {
        DispatchQueue.main.async {
          self.retryAuthenticationAlert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
          self.retryAuthenticationAlert!.addAction(title: "Retry", style: .default, handler: { _ in self.evaluatePolicyWhenUserSetEnable() })
          self.retryAuthenticationAlert!.show()
        }
      }
    }
  }
}
