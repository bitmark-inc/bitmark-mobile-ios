//
//  AccountViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import Intercom

class AccountViewController: UIViewController {

  // MARK: - Properties
  var accountNumberLabel: UIButton!
  var qrShowButton: UIButton!
  var copiedToClipboardNotifier: UILabel!
  var writeDownRecoveryPhraseButton: UIButton!
  var logoutButton: UIButton!
  var detailsButton: UIButton!
  var needHelpButton: UIButton!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.title = "ACCOUNT"
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
    setupEvents()

    loadData()
  }

  // MARK: Data Handlers
  private func loadData() {
    accountNumberLabel.setTitle(Global.currentAccount!.getAccountNumber(), for: .normal)
  }

  // MARK: - Handlers
  @objc func tapToCopyAccountNumber(_ sender: UIButton) {
    UIPasteboard.general.string = accountNumberLabel.currentTitle
    copiedToClipboardNotifier.showIn(period: 1.2)
  }

  @objc func showReceiverQR(_ sender: UIButton) {
    let qrVC = QRViewController()
    qrVC.accountNumber = accountNumberLabel.currentTitle
    presentPanModal(qrVC)
  }
}

// MARK: - setup Views/Events
extension AccountViewController {
  fileprivate func setupEvents() {
    accountNumberLabel.addTarget(self, action: #selector(tapToCopyAccountNumber), for: .touchUpInside)
    qrShowButton.addTarget(self, action: #selector(showReceiverQR), for: .touchUpInside)

    writeDownRecoveryPhraseButton.addAction(for: .touchUpInside, { [unowned self] in
      self.navigationController?.pushViewController(WarningRecoveryPhraseViewController())
    })

    logoutButton.addAction(for: .touchUpInside) {
      self.navigationController?.pushViewController(WarningRemoveAccessViewController())
    }

    detailsButton.addAction(for: .touchUpInside) {
      self.navigationController?.pushViewController(AppDetailViewController())
    }

    needHelpButton.addAction(for: .touchUpInside) {
      Intercom.presentMessenger()
    }
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let accountNumberBox = setupAccountNumberBox()

    writeDownRecoveryPhraseButton = CommonUI.actionButton(title: "WRITE DOWN RECOVERY PHRASE »")
    logoutButton = CommonUI.actionButton(title: "LOG OUT »")
    detailsButton = CommonUI.actionButton(title: "DETAILS »")
    let buttonsGroupStackView = UIStackView(
      arrangedSubviews: [
          writeDownRecoveryPhraseButton,
          logoutButton,
          detailsButton
        ],
      axis: .vertical
    )

    needHelpButton = CommonUI.linkButton(title: "NEED HELP?")
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
  }

  fileprivate func setupAccountNumberBox() -> UIView {
    let accountNumberTitleLabel = CommonUI.fieldTitleLabel(text: "YOUR BITMARK ACCOUNT NUMBER")

    qrShowButton = UIButton(type: .system, imageName: "qr-code-icon")
    qrShowButton.snp.makeConstraints { $0.width.height.equalTo(19) }

    let accountNumberView = UIStackView(arrangedSubviews: [accountNumberTitleLabel, qrShowButton])

    accountNumberLabel = UIButton(type: .system)
    accountNumberLabel.setTitleColor(.mainBlueColor, for: .normal)
    accountNumberLabel.titleLabel?.font = UIFont(name: "Courier", size: 11)
    accountNumberLabel.contentHorizontalAlignment = .fill
    accountNumberLabel.underlinedLineColor = .mainBlueColor

    copiedToClipboardNotifier = UILabel(text: "Copied to clipboard!")
    copiedToClipboardNotifier.font = UIFont(name: "Avenir", size: 8)?.italic
    copiedToClipboardNotifier.textColor = .mainBlueColor
    copiedToClipboardNotifier.textAlignment = .right
    copiedToClipboardNotifier.isHidden = true

    let accountNumberDescription = CommonUI.descriptionLabel(text: """
      To protect your privacy, you are identified in the Bitmark system by a pseudonymous account number. \
      This number is public. You can safely share it with others without compromising your security.
      """)
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
      make.top.equalTo(accountNumberLabel.snp.bottom).offset(10)
      make.leading.trailing.equalToSuperview()
    })

    accountNumberDescription.snp.makeConstraints({ (make) in
      make.top.equalTo(copiedToClipboardNotifier.snp.bottom).offset(5)
      make.leading.trailing.bottom.equalToSuperview()
    })

    return accountNumberBox
  }
}
