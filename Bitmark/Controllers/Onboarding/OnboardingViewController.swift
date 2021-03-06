//
//  OnboardingViewController.swift
//  Bitmark
//
//  Created by Thuyen Truong on 5/29/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import RxSwift
import RxFlow
import RxCocoa

class OnboardingViewController: UIViewController, Stepper {
  var steps = PublishRelay<Step>()
  let disposeBag = DisposeBag()

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

    showAccountNotAccessibleInCase()
  }

  // MARK: - Handlers
  fileprivate func showAccountNotAccessibleInCase() {
    guard UserSetting.shared.isUserLoggedIn() else { return }
    let accountNotAccessibleAlert = UIAlertController(
      title: "accountNotAccessible_title".localized(tableName: "Message"),
      message: "accountNotAccessible_message".localized(tableName: "Message")
    )
    accountNotAccessibleAlert.show()
  }

  @objc func createNewAccount(_ sender: UIButton) {
    Global.log.info("creates new account")
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
            self.navigateNextOnboardingStepFromOnboardingStep(self.steps, self.disposeBag)
            Global.log.info("finished creating new account")
          }
        }
      }
    } catch {
      showErrorAlert(message: "createAccount".localized(tableName: "Error"))
      Global.log.error(error)
    }
  }
}

extension OnboardingViewController: UITextViewDelegate {
  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
    guard URL.scheme != nil, let host = URL.host, let agreementLink = AppDetailContent(rawValue: host) else { return false }

    switch agreementLink {
    case .termsOfService:
      steps.accept(BitmarkStep.viewTermsOfService)
    case .privacyPolicy:
      steps.accept(BitmarkStep.viewPrivacyPolicy)
    }

    return true
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
    let titlePageLabel = CommonUI.pageTitleLabel(text: "onboarding_title".localized(tableName: "Phrase").localizedUppercase)
    titlePageLabel.adjustsFontSizeToFitWidth = true
    titlePageLabel.numberOfLines = 1
    titlePageLabel.textColor = .mainBlueColor

    let descriptionLabel = CommonUI.descriptionLabel(text: "onboarding_title_description".localized(tableName: "Phrase"))

    let introductionImageView = UIImageView()
    introductionImageView.image = UIImage(named: "introduction")
    introductionImageView.contentMode = .scaleAspectFit

    let introductionImageViewCover = UIView()
    introductionImageViewCover.addSubview(introductionImageView)

    introductionImageView.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
      make.height.equalTo(view.frame.height * 0.28)
    }

    let titleView = UIStackView(
      arrangedSubviews: [titlePageLabel, descriptionLabel],
      axis: .vertical,
      spacing: 30.0,
      alignment: .leading,
      distribution: .fill
    )

    let agreementTextView = UITextView()
    agreementTextView.attributedText = createTermsPrivacyAgreementText()
    agreementTextView.delegate = self
    agreementTextView.isEditable = false

    activityIndicator = CommonUI.appActivityIndicator()

    let contentView = UIView()
    contentView.addSubview(introductionImageViewCover)
    contentView.addSubview(titleView)
    contentView.addSubview(agreementTextView)
    contentView.addSubview(activityIndicator)

    titleView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    introductionImageViewCover.snp.makeConstraints { (make) in
      make.top.equalTo(titleView.snp.bottom).offset(10)
      make.leading.trailing.equalToSuperview()
      make.bottom.equalTo(agreementTextView.snp.top).offset(-10)
    }

    agreementTextView.snp.makeConstraints { (make) in
      make.height.equalTo(60)
      make.leading.trailing.equalToSuperview()
      make.bottom.equalToSuperview().offset(-10)
    }

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

    let paddingTopContent: CGFloat = view.height > 667.0 ? 100 : 50 // iphone 7 Plus and above
    let paddingContent: CGFloat = view.width <= 350 ? 30 : 50 // iphone 5S/SE and older

    contentView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
          .inset(UIEdgeInsets(top: paddingTopContent, left: paddingContent, bottom: 0, right: paddingContent))
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

  fileprivate func createTermsPrivacyAgreementText() -> NSMutableAttributedString {
    let termsOfServiceText = "TermsOfService".localized()
    let privacyPolicyText = "PrivacyPolicy".localized()
    let termsPrivacyAgreementText = String(format: "onboarding_termsPrivacyAgreement".localized(tableName: "Phrase"), termsOfServiceText, privacyPolicyText)
    let agreementText = NSMutableAttributedString(
      string: termsPrivacyAgreementText,
      attributes: [NSAttributedString.Key.font: UIFont(name: "Avenir", size: 13)!]
    )

    guard let termsOfServiceRange = termsPrivacyAgreementText.range(of: termsOfServiceText),
          let privacyPolicyRange = termsPrivacyAgreementText.range(of: privacyPolicyText) else { return agreementText }
    agreementText.addAttribute(.link,
                                value: URL(string: "bitmark://\(AppDetailContent.termsOfService.rawValue)")!,
                                range: termsPrivacyAgreementText.nsRange(from: termsOfServiceRange)
    )
    agreementText.addAttribute(.link,
                               value: URL(string: "bitmark://\(AppDetailContent.privacyPolicy.rawValue)")!,
                               range: termsPrivacyAgreementText.nsRange(from: privacyPolicyRange)
    )
    return agreementText
  }
}
