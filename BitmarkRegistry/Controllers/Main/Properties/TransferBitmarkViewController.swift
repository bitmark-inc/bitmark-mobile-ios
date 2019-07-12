//
//  TransferBitmarkViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/17/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK
import SnapKit
import Alamofire
import SwiftMessages

class TransferBitmarkViewController: UIViewController, UITextFieldDelegate {

  // MARK: - Properties
  var asset: Asset!
  var bitmarkId: String!

  var recipientAccountNumberTextfield: DesignedTextField!
  var errorForInvalidAccountNumber: UILabel!
  var transferButton: SubmitButton!
  var transferButtonBottomConstraint: Constraint!
  var scanQRButton: UIButton!
  lazy var assetFileService = {
    return AssetFileService(owner: Global.currentAccount!, assetId: asset.id)
  }()
  var networkReachabilityManager = NetworkReachabilityManager()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = asset.name
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
    setupEvents()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    addNotificationObserver(name: UIWindow.keyboardWillShowNotification, selector: #selector(keyboardWillBeShow))
    addNotificationObserver(name: UIWindow.keyboardWillHideNotification, selector: #selector(keyboardWillBeHide))

    // *** setup network reachability handlers ****
    guard let networkReachabilityManager = networkReachabilityManager else { return }
    networkReachabilityManager.listener = { [weak self] status in
      guard let self = self else { return }
      switch status {
      case .reachable:
        self.transferButton.isEnabled = self.validToTransfer()
        SwiftMessages.hide()
      default:
        SwiftMessages.show(view: CommonUI.noInternetShout())
        self.transferButton.isEnabled = false
      }
    }
    networkReachabilityManager.startListening()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    removeNotificationsObserver()
  }

  // MARK: - Handlers
  @objc func changeRecipientTextField(textfield: UITextField) {
    transferButton.isEnabled = validToTransfer()
  }

  @objc func beginEditing(textfield: UITextField) {
    errorForInvalidAccountNumber.isHidden = true
  }

  @objc func touchToScanQRCode(_ sender: UIButton) {
    let qrScannerVC = QRScannerViewController()
    qrScannerVC.delegate = self
    navigationController?.pushViewController(qrScannerVC)
  }

  @objc func tapToTransfer(button: UIButton) {
    view.endEditing(true)
    guard let recipientAccountNumber = recipientAccountNumberTextfield.text else { return }
    guard recipientAccountNumber.isValid() else {
      errorForInvalidAccountNumber.isHidden = false; return
    }

    showIndicatorAlert(message: Constant.Message.transferringTransaction) { (selfAlert) in
      do {
        _ = try BitmarkService.directTransfer(
          account: Global.currentAccount!,
          bitmarkId: self.bitmarkId,
          to: recipientAccountNumber
        )

        // upload transferred file into file courier server
        self.assetFileService.transferFile(to: recipientAccountNumber)

        selfAlert.dismiss(animated: true, completion: {
          guard let propertiesVC = self.navigationController?.viewControllers.first as? PropertiesViewController else {
            self.showErrorAlert(message: Constant.Error.cannotNavigate)
            ErrorReporting.report(error: Constant.Error.cannotNavigate)
            return
          }
          propertiesVC.syncUpdatedRecords()

          self.showSuccessAlert(message: Constant.Success.transfer, handler: {
            self.navigationController?.popToRootViewController(animated: true)
          })
        })
      } catch {
        selfAlert.dismiss(animated: true, completion: {
          self.showErrorAlert(message: error.localizedDescription)
          ErrorReporting.report(error: error)
        })
      }
    }
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    view.endEditing(true)
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    return view.endEditing(true)
  }

  func validToTransfer() -> Bool {
    return !recipientAccountNumberTextfield.isEmpty &&
           (networkReachabilityManager?.isReachable ?? false)
  }
}

// MARK: - QRCodeScannerDelegate
extension TransferBitmarkViewController: QRCodeScannerDelegate {
  func process(qrCode: String) {
    recipientAccountNumberTextfield.text = qrCode
    recipientAccountNumberTextfield.sendActions(for: .editingDidBegin)
    recipientAccountNumberTextfield.sendActions(for: .editingChanged)
  }
}

// MARK: - Setup Views/Events
extension TransferBitmarkViewController {
  fileprivate func setupEvents() {
    recipientAccountNumberTextfield.delegate = self
    recipientAccountNumberTextfield.addTarget(self, action: #selector(changeRecipientTextField), for: .editingChanged)
    recipientAccountNumberTextfield.addTarget(self, action: #selector(beginEditing), for: .editingDidBegin)
    scanQRButton.addTarget(self, action: #selector(touchToScanQRCode), for: .touchUpInside)

    transferButton.addTarget(self, action: #selector(tapToTransfer), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let transferTitle = CommonUI.inputFieldTitleLabel(text: "TRANSFER BITMARK")
    scanQRButton = UIButton(type: .system, imageName: "qr-code-scan-icon")
    scanQRButton.snp.makeConstraints { (make) in
      make.width.height.equalTo(19)
    }

    let transferView = UIStackView(arrangedSubviews: [transferTitle, scanQRButton])

    recipientAccountNumberTextfield = DesignedTextField(placeholder: "RECIPIENT BITMARK ACCOUNT NUMBER")
    recipientAccountNumberTextfield.clearButtonMode = .always
    recipientAccountNumberTextfield.returnKeyType = .done

    errorForInvalidAccountNumber = CommonUI.errorFieldLabel(text: "Invalid bitmark account number!")
    errorForInvalidAccountNumber.isHidden = true

    let descriptionLabel = CommonUI.descriptionLabel(text: "Enter the Bitmark account number to which you would like to transfer ownership of this property.")

    let mainView = UIView()
    mainView.addSubview(transferView)
    mainView.addSubview(recipientAccountNumberTextfield)
    mainView.addSubview(errorForInvalidAccountNumber)
    mainView.addSubview(descriptionLabel)

    transferView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    recipientAccountNumberTextfield.snp.makeConstraints { (make) in
      make.top.equalTo(transferTitle.snp.bottom).offset(15)
      make.leading.trailing.equalToSuperview()
    }

    errorForInvalidAccountNumber.snp.makeConstraints { (make) in
      make.top.equalTo(recipientAccountNumberTextfield.snp.bottom).offset(9)
      make.leading.trailing.equalToSuperview()
    }

    descriptionLabel.snp.makeConstraints { (make) in
      make.top.equalTo(errorForInvalidAccountNumber.snp.bottom).offset(15)
      make.leading.trailing.equalToSuperview()
    }

    transferButton = SubmitButton(title: "TRANSFER")

    // *** Setup UI in view ***
    view.addSubview(mainView)
    view.addSubview(transferButton)

    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20))
    }

    transferButton.snp.makeConstraints { (make) in
      make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      transferButtonBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
    }
  }
}

// MARK: - KeyboardObserver
extension TransferBitmarkViewController {
  @objc func keyboardWillBeShow(notification: Notification) {
    guard let userInfo = notification.userInfo else { return }
    guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

    transferButtonBottomConstraint.update(offset: -keyboardSize.height + view.safeAreaInsets.bottom)
    view.layoutIfNeeded()
  }

  @objc func keyboardWillBeHide(notification: Notification) {
    transferButtonBottomConstraint.update(offset: 0)
    view.layoutIfNeeded()
  }
}
