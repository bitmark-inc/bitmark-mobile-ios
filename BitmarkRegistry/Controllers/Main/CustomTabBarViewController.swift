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

    let accountVC = AccountViewController()
    accountVC.tabBarItem = UITabBarItem(
      title: "Account",
      image: UIImage(named: "Account-inactive"),
      selectedImage: UIImage(named: "AccountSelected")
    )

    viewControllers = [
      UINavigationController(rootViewController: accountVC)
    ]
  }
}
