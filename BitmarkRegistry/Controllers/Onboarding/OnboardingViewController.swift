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
    do {
      let account = try AccountService.createNewAccount()
      Global.currentAccount = account // track and store currentAccount
      try KeychainStore.saveToKeychain(account.seed.core)
    } catch let e {
      showErrorAlert(message: e.localizedDescription)
    }

    // redirect to Main Screen
    present(
      UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!,
      animated: true, completion: nil
    )
  }
}
