//
//  TouchAuthenticationViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/21/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class TouchAuthenticationViewController: UIViewController {

  // MARK: - Properties
  var enableButton: UIButton!
  var skipButton: UIButton!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    setupViews()
    setupEvents()
  }

  @objc func enableTouchId(_ sender: UIButton) {
    BiometricAuth().authorizeAccess { [weak self] (errorMessage) in
      guard let self = self else { return }

      DispatchQueue.main.async {
        guard errorMessage == nil else {
          let alertController = UIAlertController(title: "Error", message: errorMessage, defaultActionButtonTitle: "Cancel")
          alertController.addAction(title: "Retry", style: .default, handler: { [weak self] _ in
            self?.enableTouchId(sender)
          })
          self.present(alertController, animated: true, completion: nil)
          return
        }
        // save enable touch/face id for current account and move to main screen
        UserSetting.shared.setTouchFaceIdSetting(isEnabled: true)
        AccountService.requestJWT(account: Global.currentAccount!)

        // Go to main screen
        let homeTabbarViewController = CustomTabBarViewController()
        self.navigationController?.setViewControllers([homeTabbarViewController],
                                                      animated: true)
      }
    }
  }

  @objc func skipTouchId(_ sender: UIButton) {
    showConfirmationAlert(message: Constant.Confirmation.skipTouchFaceIdAuthentication) {
      UserSetting.shared.setTouchFaceIdSetting(isEnabled: false)
      AccountService.requestJWT(account: Global.currentAccount!)
      self.present(CustomTabBarViewController(), animated: true)
    }
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
    let titlePageLabel = CommonUI.pageTitleLabel(text: "TOUCH/FACE ID & PASSCODE")
    titlePageLabel.textColor = .mainBlueColor

    let descriptionLabel = CommonUI.descriptionLabel(text: "Turn on Touch/Face ID or a passcode to sign transactions from this device.")

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

    enableButton = CommonUI.blueButton(title: "ENABLE")
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
