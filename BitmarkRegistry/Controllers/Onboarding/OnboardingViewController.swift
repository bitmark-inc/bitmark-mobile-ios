//
//  OnboardingViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

class OnboardingViewController: UIViewController {

  // MARK: - Properties
  var registerButton: UIButton!
  var loginButton: UIButton!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    setupViews()
    setupEvents()
  }

  // MARK: - Handlers
  @objc func createNewAccount(_ sender: UIButton) {
    do {
      let account = try AccountService.createNewAccount()
      Global.currentAccount = account // track and store currentAccount
      try KeychainStore.saveToKeychain(account.seed.core)
    } catch {
      showErrorAlert(message: Constant.Error.keychainStore)
    }

    // redirect to Onboarding Screens
    present(TouchAuthenticationViewController(), animated: true)
  }
}

// MARK: - Setup Views/Events
extension OnboardingViewController {
  fileprivate func setupEvents() {
    registerButton.addTarget(self, action: #selector(createNewAccount), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let logoImageView = UIImageView()
    logoImageView.image = UIImage(named: "Bitmark_Logo-8")

    let contentView = UIView()
    contentView.addSubview(logoImageView)

    logoImageView.snp.makeConstraints({ (make) in
      make.centerX.centerY.equalToSuperview()
    })

    registerButton = CommonUI.blueButton(title: "CREATE NEW ACCOUNT")
    loginButton = CommonUI.lightButton(title: "ACCESS EXISTING ACCOUNT")
    let buttonsGroupStackView = UIStackView(
      arrangedSubviews: [registerButton, loginButton],
      axis: .vertical
    )

    // *** Setup UI in view ***
    let mainView = UIView()
    mainView.addSubview(contentView)
    mainView.addSubview(buttonsGroupStackView)

    contentView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    buttonsGroupStackView.snp.makeConstraints { (make) in
      make.top.equalTo(contentView.snp.bottom)
      make.leading.trailing.bottom.equalToSuperview()
    }

    view.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
    }
  }
}
