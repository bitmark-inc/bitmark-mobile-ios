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
  let logoImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(named: "Bitmark_Logo-8")
    return imageView
  }()

  let registerButton: UIButton = {
    let button = CommonUI.blueButton(title: "CREATE NEW ACCOUNT")
    button.addTarget(self, action: #selector(createNewAccount), for: .touchUpInside)
    return button
  }()

  let loginButton: UIButton = {
    let button = CommonUI.lightButton(title: "ACCESS EXISTING ACCOUNT")
    return button
  }()

  lazy var buttonsGroupStackView: UIStackView = {
    return UIStackView(
      arrangedSubviews: [registerButton, loginButton],
      axis: .vertical,
      spacing: 0.0,
      alignment: .fill,
      distribution: .fill
    )
  }()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    setupViews()
  }

  // MARK: - Handlers
  @objc func createNewAccount(_ sender: UIButton) {
    do {
      let account = try AccountService.createNewAccount()
      Global.currentAccount = account // track and store currentAccount
      try KeychainStore.saveToKeychain(account.seed.core)
    } catch let e {
      showErrorAlert(message: e.localizedDescription)
    }

    // redirect to Main Screen
    present(CustomTabBarViewController(), animated: true)
  }
}

// MARK: - Setup Views
extension OnboardingViewController {
  fileprivate func setupViews() {

    view.backgroundColor = .white

    // *** Setup subviews ***
    let contentView = UIView()
    contentView.addSubview(logoImageView)
    logoImageView.snp.makeConstraints({ (make) in
      make.centerX.centerY.equalToSuperview()
    })

    // *** Setup UI in view ***
    let mainView = UIView()
    view.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
    }

    mainView.addSubview(contentView)
    mainView.addSubview(buttonsGroupStackView)

    contentView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
      make.bottom.equalTo(buttonsGroupStackView.snp.top)
    }

    buttonsGroupStackView.snp.makeConstraints { (make) in
      make.leading.trailing.bottom.equalToSuperview()
    }
  }
}
