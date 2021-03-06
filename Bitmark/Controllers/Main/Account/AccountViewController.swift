//
//  AccountViewController.swift
//  Bitmark
//
//  Created by Thuyen Truong on 5/29/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import MessageUI
import RxFlow
import RxCocoa

class AccountViewController: UIViewController, Stepper {
  var steps = PublishRelay<Step>()

  // MARK: - Properties
  var accountNumberLabel: UIButton!
  var qrShowButton: UIButton!
  var copiedToClipboardNotifier: UILabel!
  var writeDownRecoveryPhraseButton: UIButton!
  var saveToiCloudDriveOption: UIView!
  var saveToiCloudDriveButton: UIButton!
  var logoutButton: UIButton!
  var detailsButton: UIButton!
  var needHelpButton: UIButton!
  let accountNumberFont = UIFont(name: Constant.andaleMono, size: 11)!
  lazy var currentAccountNumber: String = {
    return Global.currentAccount?.getAccountNumber() ?? ""
  }()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.title = "Account".localized().localizedUppercase
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
    setupEvents()

    loadData()
  }

  // MARK: Data Handlers
  private func loadData() {
    let attributedTitleString = currentAccountNumber.stretchAttributedText(
      font: accountNumberFont, width: view.width - 45
    )
    accountNumberLabel.setAttributedTitle(attributedTitleString, for: .normal)
    accountNumberLabel.contentHorizontalAlignment = .leading
    accountNumberLabel.sizeToFit()
  }

  // MARK: - Handlers
  @objc func tapToCopyAccountNumber(_ sender: UIButton) {
    UIPasteboard.general.string = currentAccountNumber
    copiedToClipboardNotifier.showIn(period: 1.2)
  }

  @objc func showReceiverQR(_ sender: UIButton) {
    let qrVC = QRViewController()
    qrVC.accountNumber = currentAccountNumber
    presentPanModal(qrVC)
  }

  @objc func saveToiCloudDrive(_ sender: UIButton) {
    steps.accept(BitmarkStep.askingiCloudSetting)
  }
}

// MARK: - setup Views/Events
extension AccountViewController {
  fileprivate func setupEvents() {
    accountNumberLabel.addTarget(self, action: #selector(tapToCopyAccountNumber), for: .touchUpInside)
    qrShowButton.addTarget(self, action: #selector(showReceiverQR), for: .touchUpInside)

    writeDownRecoveryPhraseButton.addAction(for: .touchUpInside, { [unowned self] in
      self.steps.accept(BitmarkStep.viewWarningWriteDownRecoveryPhrase)
    })

    saveToiCloudDriveButton.addTarget(self, action: #selector(saveToiCloudDrive), for: .touchUpInside)

    logoutButton.addAction(for: .touchUpInside) { [unowned self] in
      self.steps.accept(BitmarkStep.viewWarningRemoveAccess)
    }

    detailsButton.addAction(for: .touchUpInside) { [unowned self] in
      self.steps.accept(BitmarkStep.viewAppDetails)
    }

    needHelpButton.addAction(for: .touchUpInside) { [weak self] in
        let destEmail = "support@bitmark.com"
        if MFMailComposeViewController.canSendMail() {
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
             
            // Configure the fields of the interface.
            composeVC.setToRecipients([destEmail])
            composeVC.setSubject("Need help from the Bitmark app!")
            
            // Present the view controller modally.
            self?.present(composeVC, animated: true, completion: nil)
        } else {
            UIApplication.shared.open(URL(string: "mailto:\(destEmail)")!, options: [:], completionHandler: nil)
        }
    }
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let accountNumberBox = setupAccountNumberBox()

    writeDownRecoveryPhraseButton = CommonUI.actionButton(title: "WriteDownRecoveryPhrase »".localized().localizedUppercase)

    saveToiCloudDriveButton = CommonUI.actionButton(title: "SaveToiCloudDrive »".localized().localizedUppercase)
    let exclamationIcon = UIImageView(image: UIImage(named: "exclamation-icon"))
    exclamationIcon.contentMode = .scaleAspectFit
    saveToiCloudDriveOption = UIView()
    saveToiCloudDriveOption.addSubview(saveToiCloudDriveButton)
    saveToiCloudDriveOption.addSubview(exclamationIcon)

    saveToiCloudDriveButton.snp.makeConstraints { $0.top.leading.bottom.equalToSuperview() }
    exclamationIcon.snp.makeConstraints { (make) in
      make.leading.equalTo(saveToiCloudDriveButton.snp.trailing).offset(5)
      make.top.bottom.equalToSuperview()
    }

    logoutButton = CommonUI.actionButton(title: "Logout »".localized().localizedUppercase)
    detailsButton = CommonUI.actionButton(title: "Details »".localized().localizedUppercase)
    let buttonsGroupStackView = UIStackView(
      arrangedSubviews: [
          writeDownRecoveryPhraseButton,
          saveToiCloudDriveOption,
          logoutButton,
          detailsButton
        ],
      axis: .vertical
    )

    needHelpButton = CommonUI.linkButton(title: "NeedHelp?".localized().localizedUppercase)
    let needHelpView = UIStackView(
      arrangedSubviews: [CommonUI.linkSeparateLine(), needHelpButton],
      axis: .vertical,
      spacing: 8
    )

    // *** Setup UI in view ***
    let mainView = UIView()
    mainView.addSubview(accountNumberBox)
    mainView.addSubview(buttonsGroupStackView)
    mainView.addSubview(needHelpView)

    accountNumberBox.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    buttonsGroupStackView.snp.makeConstraints { (make) in
      make.top.equalTo(accountNumberBox.snp.bottom).offset(35)
      make.leading.trailing.equalToSuperview()
    }

    needHelpView.snp.makeConstraints { (make) in
      make.leading.trailing.bottom.equalToSuperview()
    }

    view.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
                .inset(UIEdgeInsets(top: 25, left: 20, bottom: 8, right: 20))
    }

    if let isiCloudEnabled = Global.isiCloudEnabled, isiCloudEnabled {
      saveToiCloudDriveOption.isHidden = true
    }
  }

  fileprivate func setupAccountNumberBox() -> UIView {
    let accountNumberTitleLabel = CommonUI.fieldTitleLabel(text: "account_accountNumberLabel".localized(tableName: "Phrase").localizedUppercase)

    qrShowButton = UIButton(type: .system, imageName: "qr-code-icon")
    qrShowButton.snp.makeConstraints { $0.width.height.equalTo(19) }

    let accountNumberView = UIStackView(arrangedSubviews: [accountNumberTitleLabel, qrShowButton])

    accountNumberLabel = UIButton(type: .system)
    accountNumberLabel.setTitleColor(.mainBlueColor, for: .normal)
    accountNumberLabel.titleLabel?.font = UIFont(name: Constant.andaleMono, size: 11)
    accountNumberLabel.titleLabel?.textAlignment = .left
    accountNumberLabel.underlinedLineColor = .mainBlueColor

    copiedToClipboardNotifier = UILabel(text: "CopiedToClipboard".localized())
    copiedToClipboardNotifier.font = UIFont(name: "Avenir-BlackOblique", size: 8)
    copiedToClipboardNotifier.textColor = .mainBlueColor
    copiedToClipboardNotifier.textAlignment = .right
    copiedToClipboardNotifier.isHidden = true

    let accountNumberDescription = CommonUI.descriptionLabel(text: "account_message".localized(tableName: "Phrase"))
    if view.height <= 568 { // adjust fit for iphone 4-inch
      accountNumberDescription.font = UIFont(name: "Avenir", size: 14)
    }
    accountNumberDescription.lineHeightMultiple(1.2)

    let accountNumberBox = UIView()
    accountNumberBox.addSubview(accountNumberView)
    accountNumberBox.addSubview(accountNumberLabel)
    accountNumberBox.addSubview(accountNumberDescription)
    accountNumberBox.addSubview(copiedToClipboardNotifier)

    accountNumberView.snp.makeConstraints({ (make) in
      make.top.leading.trailing.equalToSuperview()
    })

    accountNumberLabel.snp.makeConstraints({ (make) in
      make.top.equalTo(accountNumberTitleLabel.snp.bottom).offset(15)
      make.leading.trailing.equalToSuperview()
    })

    copiedToClipboardNotifier.snp.makeConstraints({ (make) in
      make.top.equalTo(accountNumberLabel.snp.bottom).offset(5)
      make.leading.trailing.equalToSuperview()
    })

    accountNumberDescription.snp.makeConstraints({ (make) in
      make.top.equalTo(copiedToClipboardNotifier.snp.bottom).offset(12)
      make.leading.trailing.bottom.equalToSuperview()
    })

    return accountNumberBox
  }
}

extension AccountViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
