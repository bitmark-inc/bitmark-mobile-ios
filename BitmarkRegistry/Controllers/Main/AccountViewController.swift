//
//  AccountViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class AccountViewController: UIViewController {

  // MARK: - Properties
  @IBOutlet weak var accountNumberLabel: UIButton!
  @IBOutlet weak var copiedToClipboardNotifier: UILabel!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()
    loadData()
  }

  // MARK: - Handlers
  @IBAction func tapToCopyAccountNumber(_ sender: UIButton) {
    UIPasteboard.general.string = accountNumberLabel.currentTitle
    copiedToClipboardNotifier.showIn(period: 1.2)
  }

  // MARK: Data Handlers
  private func loadData() {
    accountNumberLabel.setTitle(Global.currentAccount?.accountNumber, for: .normal)
  }
}
