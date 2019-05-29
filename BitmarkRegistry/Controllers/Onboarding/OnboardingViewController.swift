//
//  OnboardingViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class OnboardingViewController: UIViewController {

  // MARK: - Handlers
  @IBAction func createNewAccount(_ sender: UIButton) {
    let account = AccountService.createNewAccount()
    // Track and Store currentAccount
    Global.currentAccount = account
    do {
      try KeychainStore.saveToKeychain(account.seed.core)
    } catch let e {
      showInformedAlert(withTitle: "Error", message: e.localizedDescription)
    }

    // Redirect to Main Screen
    present(
      UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!,
      animated: true, completion: nil
    )
  }
}
