//
//  TransferBitmarkViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/6/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK
import AVFoundation

class TransferBitmarkViewController: UIViewController {

  // MARK: - Properties
  @IBOutlet weak var recipientAccountNumberTextfield: UITextField!
  @IBOutlet weak var  transferButton: UIButton!
  @IBOutlet weak var bottomTransferButtonConstraint: NSLayoutConstraint!
  @IBOutlet weak var errorForInvalidAccountNumber: UILabel!

  var assetName: String!
  var bitmarkId: String!

  var observers = NSPointerArray.weakObjects()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()
    title = assetName
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(true)
    registerNotifications()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    NotificationService.shared.removeNotifications(observers)
  }

  // MARK: - Handlers
  @IBAction func changeRecipientTextField(textfield: UITextField) {
    if textfield.text! != "" {
      transferButton.isEnabled = true
      textfield.rightViewMode = .always
    } else {
      transferButton.isEnabled = false
      textfield.rightViewMode = .never
    }
  }

  @IBAction func touchToCaptuerQRCode(sender: UIButton) {
    if let qrScannerViewController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "QRScannerViewController") as? QRScannerViewController {
      qrScannerViewController.delegate = self
      navigationController?.pushViewController(qrScannerViewController, animated: true)
    }
  }

  @IBAction func beginEditing(textfield: UITextField) {
    errorForInvalidAccountNumber.isHidden = true
  }

  @IBAction func tapToTransfer(button: UIButton) {
    let recipientAccountNumber = recipientAccountNumberTextfield.text!
    if recipientAccountNumber.isValid() {
      do {
        let _ = try BitmarkService.directTransfer(
          account: Global.currentAccount!,
          bitmarkId: bitmarkId,
          to: recipientAccountNumber
        )
      } catch let e {
        print(e)
        showErrorAlert(message: e.localizedDescription)
      }
    } else {
      errorForInvalidAccountNumber.isHidden = false
    }
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    view.endEditing(true)
  }
}

// MARK: - UITextFieldDelegate
extension TransferBitmarkViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    return view.endEditing(true)
  }
}

// MARK: - QRCodeScannerDelegate
extension TransferBitmarkViewController: QRCodeScannerDelegate {
  func process(qrCode: String) {
    recipientAccountNumberTextfield.text = qrCode
  }
}

// MARK: - KeyboardObserver
extension TransferBitmarkViewController: KeyboardObserver {
  private func registerNotifications() {
    for observer in registerForKeyboardNotifications() {
      NotificationService.shared.addNotification(in: &observers, with: observer)
    }
  }

  func keyboardWillBeShow(notification: Notification) {
    guard let userInfo = notification.userInfo else { return }
    let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
    bottomTransferButtonConstraint.constant = keyboardSize.height - view.safeAreaInsets.bottom
    updateLayoutWithKeyboard()
  }

  func keyboardWillBeHide(notification: Notification) {
    bottomTransferButtonConstraint.constant = 0.0
    updateLayoutWithKeyboard()
  }
}
