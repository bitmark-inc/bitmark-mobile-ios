//
//  BiometricAuthenticationViewController.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 6/21/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxFlow
import RxCocoa

class BiometricAuthenticationViewController: UIViewController, Stepper {

  // MARK: - Properties
  var steps = PublishRelay<Step>()
  var enableButton: UIButton!
  var skipButton: UIButton!
  let disposeBag = DisposeBag()

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
extension BiometricAuthenticationViewController {
  fileprivate func setupEvents() {
    enableButton.addTarget(self, action: #selector(enableSecure), for: .touchUpInside)
    skipButton.addTarget(self, action: #selector(skipSecure), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let titlePageLabel = CommonUI.pageTitleLabel(text: "facetouchid_title".localized(tableName: "Phrase").localizedUppercase)
    titlePageLabel.textColor = .mainBlueColor

    let descriptionLabel = CommonUI.descriptionLabel(text: "facetouchid_title_description".localized(tableName: "Phrase"))

    let touchFaceIdImageView = UIImageView()
    touchFaceIdImageView.image = UIImage(named: "touch-face-id")
    touchFaceIdImageView.contentMode = .scaleAspectFit

    let touchFaceIdImageViewCover = UIView()
    touchFaceIdImageViewCover.addSubview(touchFaceIdImageView)
    touchFaceIdImageView.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
      if view.width <= 320 {
        make.height.equalTo(view.frame.height * 0.3)
      }
    }

    let mainView = UIStackView(
      arrangedSubviews: [titlePageLabel, descriptionLabel],
      axis: .vertical,
      spacing: 30.0,
      alignment: .leading,
      distribution: .fill
    )

    enableButton = CommonUI.blueButton(title: "facetouchid_enableButton".localized(tableName: "Phrase"))
    skipButton = CommonUI.lightButton(title: "Skip".localized().localizedUppercase)
    let buttonsGroupStackView = UIStackView(
      arrangedSubviews: [enableButton, skipButton],
      axis: .vertical
    )

    // *** Setup UI in view ***
    view.addSubview(touchFaceIdImageViewCover)
    view.addSubview(mainView)
    view.addSubview(buttonsGroupStackView)

    let paddingTopContent: CGFloat = view.height > 667.0 ? 100 : 50 // iphone 7 Plus and above
    let paddingContent: CGFloat = view.width <= 350 ? 30 : 50 // iphone 5S/SE and older

    mainView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: paddingTopContent, left: paddingContent, bottom: 30, right: paddingContent))
    }

    touchFaceIdImageViewCover.snp.makeConstraints { (make) in
      make.top.equalTo(mainView.snp.bottom).offset(10)
      make.leading.trailing.equalToSuperview()
      make.bottom.equalTo(buttonsGroupStackView.snp.top).offset(-10)
    }

    buttonsGroupStackView.snp.makeConstraints { (make) in
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }
  }
}
