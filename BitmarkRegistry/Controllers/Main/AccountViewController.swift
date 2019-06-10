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
  let accountNumberTitleLabel: UILabel = {
    return CommonUI.fieldTitleLabel(text: "YOUR BITMARK ACCOUNT NUMBER")
                   .lineHeightMultiple(1.2)
  }()

  let accountNumberLabel: UIButton = {
    let button = UIButton(type: .system)
    button.setTitleColor(.mainBlueColor, for: .normal)
    button.titleLabel?.font = UIFont(name: "Courier", size: 11)
    button.contentHorizontalAlignment = .fill
    button.underlinedLineColor = .mainBlueColor
    button.addTarget(self, action: #selector(tapToCopyAccountNumber), for: .touchUpInside)
    return button
  }()

  let copiedToClipboardNotifier: UILabel = {
    let label = UILabel(text: "Copied to clipboard!")
    label.font = UIFont(name: "Avenir", size: 8)?.italic
    label.textColor = .mainBlueColor
    label.textAlignment = .right
    label.isHidden = true
    return label
  }()

  let accountNumberDescription: UILabel = {
    return CommonUI.descriptionLabel(text: "To protect your privacy, you are identified in the Bitmark system by a pseudonymous account number. This number is public. You can safely share it with others without compromising your security.")
                   .lineHeightMultiple(1.2)
  }()

  let writeDownRecoveryPhraseButton: UIButton = {
    let button = CommonUI.actionButton(title: "WRITE DOWN RECOVERY PHRASE »")
    return button
  }()

  let logoutButton: UIButton = {
    let button = CommonUI.actionButton(title: "LOG OUT »")
    return button
  }()

  let detailsButton: UIButton = {
    let button = CommonUI.actionButton(title: "DETAILS »")
    return button
  }()

  lazy var buttonsGroupStackView: UIStackView = {
    return UIStackView(
      arrangedSubviews: [
        writeDownRecoveryPhraseButton,
        logoutButton,
        detailsButton
      ],
      axis: .vertical,
      spacing: 0.0,
      alignment: .fill,
      distribution: .fill
    )
  }()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Account"
    setupViews()

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

// MARK: - setup Views
extension AccountViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let accountNumberBox = setupAccountNumberBox()

    // *** Setup UI in view ***
    let mainView = UIView()
    view.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
                .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20))
    }

    mainView.addSubview(accountNumberBox)
    mainView.addSubview(buttonsGroupStackView)

    accountNumberBox.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    buttonsGroupStackView.snp.makeConstraints { (make) in
      make.top.equalTo(accountNumberBox.snp.bottom).offset(45)
      make.leading.trailing.equalToSuperview()
    }
  }

  fileprivate func setupAccountNumberBox() -> UIView {
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
