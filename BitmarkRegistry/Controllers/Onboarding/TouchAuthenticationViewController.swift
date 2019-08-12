//
//  TouchAuthenticationViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/21/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import RxSwift

class TouchAuthenticationViewController: UIViewController {

  // MARK: - Properties
  var enableButton: UIButton!
  var skipButton: UIButton!
  let disposeBag = DisposeBag()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    navigationController?.isNavigationBarHidden = true

    setupViews()
    setupEvents()
  }

  @objc func enableTouchId(_ sender: UIButton) {
    UserSetting.shared.setTouchFaceIdSetting(isEnabled: true)
    saveAccountAndProcess()
  }

  @objc func skipTouchId(_ sender: UIButton) {
    showConfirmationAlert(message: Constant.Confirmation.skipTouchFaceIdAuthentication) {
      UserSetting.shared.setTouchFaceIdSetting(isEnabled: false)
      self.saveAccountAndProcess()
    }
  }

  fileprivate func saveAccountAndProcess() {
    guard let currentAccount = Global.currentAccount else { return }
    KeychainStore.saveToKeychain(currentAccount.seed.core)
      .observeOn(MainScheduler.instance)
      .subscribe(
        onCompleted: { [weak self] in
          guard let self = self else { return }
          do {
            // setup realm db & icloud db
            try RealmConfig.setupDBForCurrentAccount()
            try iCloudService.shared.setupDataFile()
            AccountDependencyService.shared.requestJWTAndIntercomAndAPNSHandler()
            let homeTabbarViewController = CustomTabBarViewController()
            self.navigationController?.setViewControllers([homeTabbarViewController], animated: true)
          } catch {
            ErrorReporting.report(error: error)
            self.navigationController?.viewControllers = [SuspendedViewController()]
          }
        },
        onError: { [weak self] (_) in
          self?.showErrorAlert(message: Constant.Error.keychainStore)
        })
      .disposed(by: self.disposeBag)
  }
}

// MARK: - Setup Views/Events
extension TouchAuthenticationViewController {
  fileprivate func setupEvents() {
    enableButton.addTarget(self, action: #selector(enableTouchId), for: .touchUpInside)
    skipButton.addTarget(self, action: #selector(skipTouchId), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let titlePageLabel = CommonUI.pageTitleLabel(text: "TOUCH/FACE ID")
    titlePageLabel.textColor = .mainBlueColor

    let descriptionLabel = CommonUI.descriptionLabel(text: "Use Touch/Face ID to sign and encrypt your data.")

    let touchFaceIdImageView = UIImageView()
    touchFaceIdImageView.image = UIImage(named: "touch-face-id")
    touchFaceIdImageView.contentMode = .scaleAspectFit

    let mainView = UIStackView(
      arrangedSubviews: [titlePageLabel, descriptionLabel],
      axis: .vertical,
      spacing: 50.0,
      alignment: .leading,
      distribution: .fill
    )

    enableButton = CommonUI.blueButton(title: "ENABLE TOUCH/FACE ID")
    skipButton = CommonUI.lightButton(title: "SKIP")
    let buttonsGroupStackView = UIStackView(
      arrangedSubviews: [enableButton, skipButton],
      axis: .vertical
    )

    // *** Setup UI in view ***
    view.addSubview(touchFaceIdImageView)
    view.addSubview(mainView)
    view.addSubview(buttonsGroupStackView)

    mainView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 50, left: 30, bottom: 30, right: 0))
    }

    touchFaceIdImageView.snp.makeConstraints { (make) in
      make.top.equalTo(mainView.snp.bottom)
      make.centerX.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      make.height.equalTo(view.snp.height).multipliedBy(0.4)
    }

    buttonsGroupStackView.snp.makeConstraints { (make) in
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }
  }
}
