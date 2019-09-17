//
//  PasscodeAuthenticationViewController.swift
//  Bitmark
//
//  Created by Thuyen Truong on 9/3/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxFlow
import RxCocoa

class PasscodeAuthenticationViewController: UIViewController, Stepper {

  // MARK: - Properties
  var steps = PublishRelay<Step>()
  let disposeBag = DisposeBag()
  var enableButton: UIButton!
  var skipButton: UIButton!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    setupViews()
    setupEvents()
  }

  @objc func enableSecure(_ sender: UIButton) {
    UserSetting.shared.setTouchFaceIdSetting(isEnabled: true)
    requireAuthenticationForAction(disposeBag) { [weak self] in
      guard let self = self else { return }
      self.saveAccountAndProcess(self.steps, self.disposeBag)
    }
  }

  @objc func skipSecure(_ sender: UIButton) {
    UserSetting.shared.setTouchFaceIdSetting(isEnabled: false)
    saveAccountAndProcess(steps, disposeBag)
  }
}

// MARK: - Setup Views/Events
extension PasscodeAuthenticationViewController {
  fileprivate func setupEvents() {
    enableButton.addTarget(self, action: #selector(enableSecure), for: .touchUpInside)
    skipButton.addTarget(self, action: #selector(skipSecure), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let titlePageLabel = CommonUI.pageTitleLabel(text: "facetouchid_passcode_title".localized(tableName: "Phrase").localizedUppercase)
    titlePageLabel.textColor = .mainBlueColor

    let descriptionLabel = CommonUI.descriptionLabel(text: "facetouchid_passcode_title_description".localized(tableName: "Phrase"))

    let passcodeImageView = UIImageView()
    passcodeImageView.image = UIImage(named: "passcode-lock")
    passcodeImageView.contentMode = .scaleAspectFit

    let mainView = UIStackView(
      arrangedSubviews: [titlePageLabel, descriptionLabel],
      axis: .vertical,
      spacing: 30.0,
      alignment: .leading,
      distribution: .fill
    )

    enableButton = CommonUI.blueButton(title: "facetouchid_passcode_enableButton".localized(tableName: "Phrase"))
    skipButton = CommonUI.lightButton(title: "Skip".localized().localizedUppercase)
    let buttonsGroupStackView = UIStackView(
      arrangedSubviews: [enableButton, skipButton],
      axis: .vertical
    )

    // *** Setup UI in view ***
    view.addSubview(passcodeImageView)
    view.addSubview(mainView)
    view.addSubview(buttonsGroupStackView)

    let paddingTopContent: CGFloat = view.height > 667.0 ? 100 : 50 // iphone 7 Plus and above
    let paddingContent: CGFloat = view.width <= 350 ? 30 : 50 // iphone 5S/SE and older

    mainView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
        .inset(UIEdgeInsets(top: paddingTopContent, left: paddingContent, bottom: 30, right: paddingContent))
    }

    passcodeImageView.snp.makeConstraints { (make) in
      make.top.lessThanOrEqualTo(mainView.snp.bottom).offset(50)
      make.leading.trailing.equalToSuperview()
      make.bottom.lessThanOrEqualTo(buttonsGroupStackView.snp.top).offset(-20)

      if view.width <= 350 {
        make.height.equalToSuperview().multipliedBy(0.1)
      }
    }

    buttonsGroupStackView.snp.makeConstraints { (make) in
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }
  }
}
