//
//  DashboardFlow.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/19/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import UserNotifications
import RxFlow

class DashboardFlow: Flow {
  var root: Presentable {
    return self.rootViewController
  }
  let rootViewController = UITabBarController()

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? BitmarkStep else { return .none }

    switch step {
    case .dashboardIsRequired:
      return navigateToDashboard()
    case .dashboardIsComplete:
      return .end(forwardToParentFlowWithStep: BitmarkStep.onboardingIsRequired)
    default:
      return .none
    }
  }

  private func navigateToDashboard() -> FlowContributors {
    let propertiesFlow = PropertiesFlow()
    let propertiesStepper = PropertiesStepper.shared
    let transactionsFlow = TransactionsFlow()
    let accountFlow = AccountFlow()

    Flows.whenReady(flow1: propertiesFlow, flow2: transactionsFlow, flow3: accountFlow) { [unowned self] (root1: UINavigationController, root2: UINavigationController, root3: UINavigationController) in

      let propertiesTabBarItem = UITabBarItem(
        title: "Properties".localized(),
        image: UIImage(named: "Properties - inactive"),
        selectedImage: UIImage(named: "Properties - selected")
      )

      let transactionsTabBarItem = UITabBarItem(
        title: "Transactions".localized(),
        image: UIImage(named: "Transactions - inactive"),
        selectedImage: UIImage(named: "Transactions - selected")
      )

      let accountTabBarItem = UITabBarItem(
        title: "Account".localized(),
        image: UIImage(named: "Account-inactive"),
        selectedImage: UIImage(named: "AccountSelected")
      )
      self.setupBadgeForAccountTabBarItem(accountTabBarItem)

      root1.tabBarItem = propertiesTabBarItem
      root2.tabBarItem = transactionsTabBarItem
      root3.tabBarItem = accountTabBarItem

      self.rootViewController.setViewControllers([root1, root2, root3], animated: false)

      // Remove top line from tabBar
      self.rootViewController.tabBar.shadowImage = UIImage()
      self.rootViewController.tabBar.backgroundImage = UIImage()
      self.rootViewController.tabBar.backgroundColor = .wildSand

      guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

      // Register APNS: when user access into Dashboard
      UNUserNotificationCenter.current()
        .requestAuthorization(options: [.alert, .sound, .badge]) {(granted, _) in
          if granted {
            UNUserNotificationCenter.current().delegate = appDelegate
          } else {
            appDelegate.registerAPNSSubject.onCompleted()
          }
      }

      UIApplication.shared.registerForRemoteNotifications()
    }

    return .multiple(flowContributors: [
      .contribute(withNextPresentable: propertiesFlow, withNextStepper: propertiesStepper),
      .contribute(withNextPresentable: transactionsFlow, withNextStepper: OneStepper(withSingleStep: BitmarkStep.listOfTransactions)),
      .contribute(withNextPresentable: accountFlow, withNextStepper: OneStepper(withSingleStep: BitmarkStep.viewAccountDetails))
    ])
  }

  func setupBadgeForAccountTabBarItem(_ accountTabBarItem: UITabBarItem) {
    guard let currentAccountNumber = Global.currentAccount?.getAccountNumber() else { return }
    Global.isiCloudEnabled = KeychainStore.getiCloudSettingFromKeychain(currentAccountNumber)
    guard let isiCloudEnabled = Global.isiCloudEnabled else { return }
    accountTabBarItem.badgeValue = isiCloudEnabled ? nil : "●"
    accountTabBarItem.badgeColor = .clear
    accountTabBarItem.setBadgeTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.red], for: .normal)
  }
}
