//
//  CustomTabBarViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/10/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class CustomTabBarViewController: UITabBarController {

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    let propertiesVC = PropertiesViewController()
    propertiesVC.tabBarItem = setupPropertiesTabBarItem()

    let transactionsVC = TransactionsViewController()
    transactionsVC.tabBarItem = setupTransactionsTabBarItem()

    let accountVC = AccountViewController()
    accountVC.tabBarItem = setupAccountTabBarItem()

    viewControllers = [
      UINavigationController(rootViewController: propertiesVC),
      UINavigationController(rootViewController: transactionsVC),
      UINavigationController(rootViewController: accountVC)
    ]
  }

  // MARK: - Setup TabBarItems
  fileprivate func setupPropertiesTabBarItem() -> UITabBarItem {
    return UITabBarItem(
      title: "Properties".localized(),
      image: UIImage(named: "Properties - inactive"),
      selectedImage: UIImage(named: "Properties - selected")
   )
  }

  fileprivate func setupTransactionsTabBarItem() -> UITabBarItem {
    return UITabBarItem(
      title: "Transactions".localized(),
      image: UIImage(named: "Transactions - inactive"),
      selectedImage: UIImage(named: "Transactions - selected")
    )
  }

  fileprivate func setupAccountTabBarItem() -> UITabBarItem {
    return UITabBarItem(
      title: "Account".localized(),
      image: UIImage(named: "Account-inactive"),
      selectedImage: UIImage(named: "AccountSelected")
    )
  }
}
