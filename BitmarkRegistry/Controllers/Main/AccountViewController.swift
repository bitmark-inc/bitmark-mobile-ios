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
  var accountNumberLabel: UIButton!
  var copiedToClipboardNotifier: UILabel!
  var writeDownRecoveryPhraseButton: UIButton!
  var logoutButton: UIButton!
  var detailsButton: UIButton!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Account"
    setupViews()
    setupEvents()

    loadData()
  }

  // MARK: - Handlers
  @objc func tapToCopyAccountNumber(_ sender: UIButton) {
    UIPasteboard.general.string = accountNumberLabel.currentTitle
    copiedToClipboardNotifier.showIn(period: 1.2)
  }

  // MARK: Data Handlers
  private func loadData() {
    accountNumberLabel.setTitle(Global.currentAccount!.getAccountNumber(), for: .normal)
  }
}

// MARK: - setup Views/Events
extension AccountViewController {
  fileprivate func setupEvents() {
    accountNumberLabel.addTarget(self, action: #selector(tapToCopyAccountNumber), for: .touchUpInside)
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

    // *** Setup UI in view ***
    let mainView = UIView()
    mainView.addSubview(accountNumberBox)
    mainView.addSubview(buttonsGroupStackView)

    accountNumberBox.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    buttonsGroupStackView.snp.makeConstraints { (make) in
      make.top.equalTo(accountNumberBox.snp.bottom).offset(45)
      make.leading.trailing.equalToSuperview()
    }

    view.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
                .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20))
    }
  }

  fileprivate func setupAccountNumberBox() -> UIView {
    let accountNumberTitleLabel = CommonUI.fieldTitleLabel(text: "YOUR BITMARK ACCOUNT NUMBER")

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

    let accountNumberDescription = CommonUI.descriptionLabel(text: "To protect your privacy, you are identified in the Bitmark system by a pseudonymous account number. This number is public. You can safely share it with others without compromising your security.").lineHeightMultiple(1.2)

    let accountNumberBox = UIView()
    accountNumberBox.addSubview(accountNumberTitleLabel)
    accountNumberBox.addSubview(accountNumberLabel)
    accountNumberBox.addSubview(accountNumberDescription)
    accountNumberBox.addSubview(copiedToClipboardNotifier)

    accountNumberTitleLabel.snp.makeConstraints({ (make) in
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
