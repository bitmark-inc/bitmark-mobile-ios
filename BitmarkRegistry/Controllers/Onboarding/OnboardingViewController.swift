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
import RxFlow
import RxCocoa

class OnboardingViewController: UIViewController, Stepper {
  var steps = PublishRelay<Step>()

  // MARK: - Properties
  var registerButton: UIButton!
  var loginButton: UIButton!
  var activityIndicator: UIActivityIndicatorView!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.backBarButtonItem = UIBarButtonItem()

    setupViews()
    setupEvents()
  }

  // MARK: - Handlers
  @objc func createNewAccount(_ sender: UIButton) {
    activityIndicator.startAnimating()
    do {
      try AccountService.createNewAccount { [weak self] (account, error) in
        guard let self = self else { return }
        DispatchQueue.main.async {
          self.activityIndicator.stopAnimating()
          if let error = error {
            self.showErrorAlert(message: error.localizedDescription)
          }

          if let account = account {
            Global.currentAccount = account // track and store currentAccount
            UserSetting.shared.setAccountVersion(.v2)
            self.steps.accept(BitmarkStep.askingTouchFaceIdAuthentication)
          }
        }
      }
    } catch {
      showErrorAlert(message: "createAccount".localized(tableName: "Error"))
      ErrorReporting.report(error: error)
    }
  }
}

// MARK: - Setup Views/Events
extension OnboardingViewController {
  fileprivate func setupEvents() {
    registerButton.addTarget(self, action: #selector(createNewAccount), for: .touchUpInside)
    loginButton.addAction(for: .touchUpInside) { [weak self] in
      self?.steps.accept(BitmarkStep.testLogin)
    }
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let logoImageView = UIImageView()
    logoImageView.image = UIImage(named: "Bitmark_Logo-8")

    activityIndicator = CommonUI.appActivityIndicator()

    let contentView = UIView()
    contentView.addSubview(logoImageView)
    contentView.addSubview(activityIndicator)

    logoImageView.snp.makeConstraints({ (make) in
      make.centerX.centerY.equalToSuperview()
    })

    activityIndicator.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview().offset(100)
    }

    registerButton = CommonUI.blueButton(title: "CreateNewAccount".localized().localizedUppercase)
    loginButton = CommonUI.lightButton(title: "AccessExistingAccount".localized().localizedUppercase)
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
