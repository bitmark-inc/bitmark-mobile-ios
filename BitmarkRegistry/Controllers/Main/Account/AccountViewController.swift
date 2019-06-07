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
  @IBOutlet weak var qrImage: UIImageView!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()
    loadData()

    qrImage.image = "abce".generateQRCode()
  }

  // MARK: - Handlers
  @IBAction func tapToCopyAccountNumber(_ sender: UIButton) {
    UIPasteboard.general.string = accountNumberLabel.currentTitle
    copiedToClipboardNotifier.showIn(period: 1.2)
  }

  @IBAction func showReceiverQR(_ sender: UIButton) {
    print("dasasd")
    let alertController = UIAlertController(title: "dafasdf", message: "", preferredStyle: .actionSheet)

    let customReceiverQRView = CustomReceiverQRView()
    customReceiverQRView.qrImage.image = "dafasdfadfa".generateQRCode()

    alertController.view.addSubview(customReceiverQRView)
    customReceiverQRView.translatesAutoresizingMaskIntoConstraints = false
    customReceiverQRView.fixInView(alertController.view)

    alertController.view.heightAnchor.constraint(equalToConstant: view.frame.height * 0.8) .isActive = true

    present(alertController, animated: true, completion: nil)
  }

  // MARK: Data Handlers
  private func loadData() {
    accountNumberLabel.setTitle(Global.currentAccount?.getAccountNumber(), for: .normal)
  }
}
