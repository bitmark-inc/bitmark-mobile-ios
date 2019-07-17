//
//  AppDelegate.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift
import Sentry
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var retryAuthenticationAlert: UIAlertController?

  // Reactive
  private let disposeBag = DisposeBag()
  private let registerAPNSSubject = PublishSubject<String>()

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // init BitmarkSDK environment & api_token
    BitmarkSDKService.setupConfig()

    IQKeyboardManager.shared.enable = true
    IQKeyboardManager.shared.shouldResignOnTouchOutside = true

    window = UIWindow(frame: UIScreen.main.bounds)
    window?.makeKeyAndVisible()

    // Redirect Screen for new user / existing user
    let initialVC = AccountService.existsCurrentAccount()
                          ? CustomTabBarViewController()
                          : OnboardingViewController()

    // Add navigation controller
    let navigationController = UINavigationController(rootViewController: initialVC)
    navigationController.isNavigationBarHidden = true
    window?.rootViewController = navigationController

    // Register APNS
    UIApplication.shared.registerForRemoteNotifications()

    evaluatePolicyWhenUserSetEnable()
    initSentry()
    Global.log.logAppDetails()

    // setup realm db
    do {
      try RealmConfig.setupDBForCurrentAccount()
    } catch {
      ErrorReporting.report(error: error)
      window?.rootViewController = SuspendedViewController()
    }

    return true
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state.
    // This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
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
    Global.syncNewDataInStorage()
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }

  func application(_ application: UIApplication,
                   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    var token = ""
    for i in 0..<deviceToken.count {
      token += String(format: "%02.2hhx", arguments: [deviceToken[i]])
    }

    registerAPNSSubject.onNext(token)
    registerAPNSSubject.onCompleted()
  }

  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    registerAPNSSubject.onError(error)
    registerAPNSSubject.onCompleted()
  }

}

private extension AppDelegate {

  /**
   1. evaluate Touch/Face Id
   2. request mobile_server_url to get and store jwt
   */
  func evaluatePolicyWhenUserSetEnable() {
    guard let currentAccount = Global.currentAccount else { return }

    let requestJWTAndAPNSHandler: () -> Void = { [weak self] in
      guard let self = self else { return }
      Observable.zip(AccountService.requestJWT(account: currentAccount),
                     self.registerAPNSSubject.asObservable())
        .flatMap { (_, token) -> Observable<Void> in
        return AccountService.registerAPNS(token: token)
      }.subscribeOn(SerialDispatchQueueScheduler(qos: .background))
        .subscribe(onError: { (error) in
          ErrorReporting.report(error: error)
          Global.log.error(error)
        }, onCompleted: {
          Global.log.info("Finish registering jwt and apns.")
        }).disposed(by: self.disposeBag)
    }

    guard UserSetting.shared.getTouchFaceIdSetting() else {
      requestJWTAndAPNSHandler()
      return
    }
    retryAuthenticationAlert?.dismiss(animated: false, completion: nil)

    BiometricAuth().authorizeAccess { [weak self] (errorMessage) in
      guard let self = self else { return }
      DispatchQueue.main.async {
        if let errorMessage = errorMessage {
          self.retryAuthenticationAlert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
          self.retryAuthenticationAlert!.addAction(title: "Retry", style: .default, handler: { _ in self.evaluatePolicyWhenUserSetEnable() })
          self.retryAuthenticationAlert!.show()
        } else {
          requestJWTAndAPNSHandler()
        }
      }
    }
  }

  // Create a Sentry client and start crash handler
  func initSentry() {
    do {
      Client.shared = try Client(dsn: "https://92d49f612d5f4cd89427cef0cd39794f@sentry.io/1494841")
      Client.shared?.trackMemoryPressureAsEvent()
      try Client.shared?.startCrashHandler()
    } catch {
      Global.log.error(error)
    }
  }
}
