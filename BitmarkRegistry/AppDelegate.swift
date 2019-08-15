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
import Intercom
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var retryAuthenticationAlert: UIAlertController?

  var registerAPNSSubject = ReplaySubject<String>.create(bufferSize: 1)
  let disposeBag = DisposeBag()

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // init BitmarkSDK environment & api_token
    BitmarkSDKService.setupConfig()

    IQKeyboardManager.shared.enable = true
    IQKeyboardManager.shared.shouldResignOnTouchOutside = true
    IQKeyboardManager.shared.enableAutoToolbar = false

    window = UIWindow(frame: UIScreen.main.bounds)
    window?.makeKeyAndVisible()

    // Redirect Screen for new user / existing user
    let navigationVC = UINavigationController(rootViewController: AppNavigationViewController())
    navigationVC.isNavigationBarHidden = true
    window?.rootViewController = navigationVC

    // Register APNS
    UNUserNotificationCenter.current()
      .requestAuthorization(options: [.alert, .sound, .badge])
       { [weak self] (granted, error) in
        if granted {
          UNUserNotificationCenter.current().delegate = self
        }
       }
    
    UIApplication.shared.registerForRemoteNotifications()

    evaluatePolicyWhenUserSetEnable()
    initSentry()
    Global.log.logAppDetails()
    
    // Check if launched from notification
    let notificationOption = launchOptions?[.remoteNotification]

    if let notification = notificationOption as? [String: AnyObject],
      let aps = notification["aps"] as? [String: AnyObject] {
      Global.log.debug(aps)
    }

    // setup intercom
    let intercomApiKey = Credential.valueForKey(keyName: Constant.InfoKey.intercomAppKey)
    let intercomApiId = Credential.valueForKey(keyName: Constant.InfoKey.intercomAppId)
    Intercom.setApiKey(intercomApiKey, forAppId: intercomApiId)

    // setup realm db
    do {
      try RealmConfig.setupDBForCurrentAccount()
    } catch {
      ErrorReporting.report(error: error)
      window?.rootViewController = SuspendedViewController()
        DispatchQueue.global(qos: .utility).async {
          iCloudService.shared.migrateFileData()
        }
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
    if Global.currentAccount != nil {
      evaluatePolicyWhenUserSetEnable()
      Global.syncNewDataInStorage()
    }
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
    #if !targetEnvironment(simulator)
      registerAPNSSubject.onError(error)
    #endif
    registerAPNSSubject.onCompleted()
  }

  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    guard let _ = url.scheme, let host = url.host else { return false }

    switch host {
    case "authorization":
      let verificationLink = String(url.path.dropFirst())
      Global.verificationLink = verificationLink

      if Global.currentAccount == nil {
        showAuthorizationRequiredAlert()
      } else {
        let navigationController = UINavigationController(rootViewController: CustomTabBarViewController())
        navigationController.isNavigationBarHidden = true
        window?.rootViewController = navigationController
      }
    default:
      return false
    } 

    return true
  }
}

private extension AppDelegate {

  /**
   1. evaluate Touch/Face Id
   2. request mobile_server_url to get and store jwt
   */
  func evaluatePolicyWhenUserSetEnable() {
    guard Global.currentAccount != nil else { return }
    guard UserSetting.shared.getTouchFaceIdSetting() && KeychainStore.isAccountExpired() else {
      AccountDependencyService.shared.requestJWTAndIntercomAndAPNSHandler()
      return
    }
    retryAuthenticationAlert?.dismiss(animated: false, completion: nil)

    AccountService.shared.existsCurrentAccount()
      .subscribe(onSuccess: { (_) in
        AccountDependencyService.shared.requestJWTAndIntercomAndAPNSHandler()
      }, onError: { [weak self] (error) in
        guard let self = self else { return }
        self.retryAuthenticationAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        self.retryAuthenticationAlert!.addAction(title: "Retry", style: .default, handler: { _ in self.evaluatePolicyWhenUserSetEnable() })
        self.retryAuthenticationAlert!.show()
      })
      .disposed(by: disposeBag)
  }

  func showAuthorizationRequiredAlert() {
    let authorizationRequired = Constant.Confirmation.authorizationRequired
    let message = authorizationRequired.requiredAccountMessage

    let alertController = UIAlertController(title: authorizationRequired.title, message: message, defaultActionButtonTitle: "OK")
    alertController.show()
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
