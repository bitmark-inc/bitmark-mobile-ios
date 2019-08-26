//
//  AccountViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import Intercom
import RxFlow
import RxCocoa

class AccountViewController: UIViewController, Stepper {
  var steps = PublishRelay<Step>()

  // MARK: - Properties
  var accountNumberLabel: UIButton!
  var qrShowButton: UIButton!
  var copiedToClipboardNotifier: UILabel!
  var writeDownRecoveryPhraseButton: UIButton!
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
    let attributedTitleString = stretchAttributedText(
      text: currentAccountNumber,
      font: accountNumberFont, width: view.width - 45
    )
    accountNumberLabel.setAttributedTitle(attributedTitleString, for: .normal)
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
}

// MARK: - setup Views/Events
extension AccountViewController {
  fileprivate func setupEvents() {
    accountNumberLabel.addTarget(self, action: #selector(tapToCopyAccountNumber), for: .touchUpInside)
    qrShowButton.addTarget(self, action: #selector(showReceiverQR), for: .touchUpInside)

    writeDownRecoveryPhraseButton.addAction(for: .touchUpInside, { [unowned self] in
      self.steps.accept(BitmarkStep.viewWarningWriteDownRecoveryPhrase)
    })

    logoutButton.addAction(for: .touchUpInside) { [unowned self] in
      self.steps.accept(BitmarkStep.viewWarningRemoveAccess)
    }

    detailsButton.addAction(for: .touchUpInside) { [unowned self] in
      self.steps.accept(BitmarkStep.viewAppDetails)
    }

    needHelpButton.addAction(for: .touchUpInside) {
      Intercom.presentMessenger()
    }
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let accountNumberBox = setupAccountNumberBox()

    writeDownRecoveryPhraseButton = CommonUI.actionButton(title: "WriteDownRecoveryPhrase »".localized().localizedUppercase)
    logoutButton = CommonUI.actionButton(title: "Logout »".localized().localizedUppercase)
    detailsButton = CommonUI.actionButton(title: "Details »".localized().localizedUppercase)
    let buttonsGroupStackView = UIStackView(
      arrangedSubviews: [
          writeDownRecoveryPhraseButton,
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
    copiedToClipboardNotifier.font = UIFont(name: "Avenir-Black", size: 8)?.italic
    copiedToClipboardNotifier.textColor = .mainBlueColor
    copiedToClipboardNotifier.textAlignment = .right
    copiedToClipboardNotifier.isHidden = true

    let accountNumberDescription = CommonUI.descriptionLabel(text: "account_message".localized(tableName: "Phrase"))
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

  fileprivate func stretchAttributedText(text: String, font: UIFont, width: CGFloat) -> NSMutableAttributedString {
    let attrStr = NSMutableAttributedString(string: text)
    let textWidth = text.size(withAttributes: [.font: font]).width
    let letterSpacing = (width - textWidth) / CGFloat(text.count)
    attrStr.addAttribute(NSAttributedString.Key.kern, value: letterSpacing, range: NSMakeRange(0, attrStr.length))

    return attrStr
  }
}
