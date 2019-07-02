//
//  CustomTabBarViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/10/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class CustomTabBarViewController: UITabBarController {

  override func viewDidLoad() {
    super.viewDidLoad()

    let propertiesVC = PropertiesViewController()
    propertiesVC.tabBarItem = UITabBarItem(
      title: "Account",
      image: UIImage(named: "Properties - inactive"),
      selectedImage: UIImage(named: "Properties - selected")
    )

    let transactionsVC = TransactionsViewController()
    transactionsVC.tabBarItem = UITabBarItem(
      title: "Transactions",
      image: UIImage(named: "Transactions - inactive"),
      selectedImage: UIImage(named: "Transactions - selected")
    )

    let accountVC = AccountViewController()
    accountVC.tabBarItem = UITabBarItem(
      title: "Account",
      image: UIImage(named: "Account-inactive"),
      selectedImage: UIImage(named: "AccountSelected")
    )

    viewControllers = [
      UINavigationController(rootViewController: propertiesVC),
      UINavigationController(rootViewController: transactionsVC),
      UINavigationController(rootViewController: accountVC)
    ]
  }
}
