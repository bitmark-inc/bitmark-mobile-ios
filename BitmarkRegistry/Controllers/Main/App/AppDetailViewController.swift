//
//  AppDetailViewController.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 7/11/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxFlow
import RxCocoa

class AppDetailViewController: UIViewController, Stepper {
  var steps = PublishRelay<Step>()

  // MARK: - Properties
  let productURL = URL(string: "https://apps.apple.com/us/app/bitmark/id1429427796")!
  var termsOfServiceLink: UIButton!
  var privacyPolicyLink: UIButton!
  var versionInfoLabel: UILabel!
  var whatNewLink: UIButton!
  var appStoreReviewLink: UIButton!
  var shareThisAppLink: UIButton!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Details".localized().localizedUppercase
    navigationItem.backBarButtonItem = UIBarButtonItem()

    setupViews()
    setupEvents()

    loadData()
  }

  // MARK: - Data Handlers
  fileprivate func loadData() {
    if let infoDiction = Bundle.main.infoDictionary,
       let appVersion = infoDiction[Constant.InfoKey.kVersion] as? String,
       let bundle = infoDiction[Constant.InfoKey.kBundle] as? String {
      versionInfoLabel.text = "\(appVersion) (\(bundle))"
    }
  }

  // MARK: - Handlers
  @objc func gotoAppStoreReview() {
    guard var components = URLComponents(url: productURL, resolvingAgainstBaseURL: false) else { return }
    components.queryItems = [
      URLQueryItem(name: "action", value: "write-review")
    ]

    guard let writeReviewURL = components.url else { return }
    UIApplication.shared.open(writeReviewURL)
  }

  @objc func shareThisApp() {
    let activityVC = UIActivityViewController(activityItems: [productURL], applicationActivities: [])
    present(activityVC, animated: true)
  }
}

// MARK: - Setup Views/Events
extension AppDetailViewController {
  fileprivate func setupEvents() {
    termsOfServiceLink.addAction(for: .touchUpInside) { [weak self] in
      self?.steps.accept(BitmarkStep.viewTermsOfService)
    }
    privacyPolicyLink.addAction(for: .touchUpInside) { [weak self] in
      self?.steps.accept(BitmarkStep.viewPrivacyPolicy)
    }
    whatNewLink.addAction(for: .touchUpInside) { [weak self] in
      self?.steps.accept(BitmarkStep.viewReleaseNotes)
    }
    appStoreReviewLink.addTarget(self, action: #selector(gotoAppStoreReview), for: .touchUpInside)
    shareThisAppLink.addTarget(self, action: #selector(shareThisApp), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    termsOfServiceLink = CommonUI.linkButton(title: AppDetailContent.termsOfService.title())
    privacyPolicyLink = CommonUI.linkButton(title: AppDetailContent.privacyPolicy.title())

    // *** Setup subviews ***
    let topStackView = UIStackView(
      arrangedSubviews: [termsOfServiceLink, CommonUI.linkSeparateLine(), privacyPolicyLink, CommonUI.linkSeparateLine()],
      axis: .vertical,
      spacing: 8
    )

    let versionTitle = infoLabel("Version:".localized())
    versionInfoLabel = infoLabel()
    let versionInfoView = UIStackView(arrangedSubviews: [versionTitle, versionInfoLabel], axis: .horizontal, spacing: 8)

    let versionView = UIView()
    versionView.addSubview(versionInfoView)

    versionInfoView.snp.makeConstraints { (make) in
      make.top.equalToSuperview().offset(18)
    }

    whatNewLink = CommonUI.linkButton(title: "appDetails_whatsnew".localized(tableName: "Phrase").localizedUppercase)
    appStoreReviewLink = CommonUI.linkButton(title: "appDetails_appStore&Review".localized(tableName: "Phrase").localizedUppercase)
    shareThisAppLink = CommonUI.linkButton(title: "appDetails_shareThisApp".localized(tableName: "Phrase").localizedUppercase)

    let bottomStackView = UIStackView(
      arrangedSubviews: [whatNewLink, CommonUI.linkSeparateLine(), appStoreReviewLink, CommonUI.linkSeparateLine(), shareThisAppLink],
      axis: .vertical,
      spacing: 8
    )

    // *** Setup UI in view ***
    let mainView = UIView()
    mainView.addSubview(topStackView)
    mainView.addSubview(versionView)
    mainView.addSubview(bottomStackView)

    topStackView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    versionView.snp.makeConstraints { (make) in
      make.top.equalTo(topStackView.snp.bottom)
      make.leading.trailing.equalToSuperview()
    }

    bottomStackView.snp.makeConstraints { (make) in
      make.top.equalTo(versionView.snp.bottom)
      make.leading.trailing.bottom.equalToSuperview()
    }

    view.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 8, right: 20))
    }
  }

  fileprivate func infoLabel(_ text: String = "") -> UILabel {
    let label = UILabel(text: text)
    label.font = UIFont(name: Constant.andaleMono, size: 14)
    return label
  }
}
