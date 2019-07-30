//
//  AppDetailViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class AppDetailViewController: UIViewController {

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

    title = "DETAILS"
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
  @objc func gotoTermsOfService() {
    let appDetailContentVC = AppDetailContentViewController()
    appDetailContentVC.appDetailContent = .termsOfService
    navigationController?.pushViewController(appDetailContentVC)
  }

  @objc func gotoPrivacyPolicy() {
    let appDetailContentVC = AppDetailContentViewController()
    appDetailContentVC.appDetailContent = .privacyPolicy
    navigationController?.pushViewController(appDetailContentVC)
  }

  @objc func gotoReleaseNotes() {
    let releaseNotesContentVC = ReleaseNotesViewController()
    navigationController?.pushViewController(releaseNotesContentVC)
  }

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
    termsOfServiceLink.addTarget(self, action: #selector(gotoTermsOfService), for: .touchUpInside)
    privacyPolicyLink.addTarget(self, action: #selector(gotoPrivacyPolicy), for: .touchUpInside)

    whatNewLink.addTarget(self, action: #selector(gotoReleaseNotes), for: .touchUpInside)
    appStoreReviewLink.addTarget(self, action: #selector(gotoAppStoreReview), for: .touchUpInside)
    shareThisAppLink.addTarget(self, action: #selector(shareThisApp), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    termsOfServiceLink = linkButton(title: AppDetailContent.termsOfService.title())
    privacyPolicyLink = linkButton(title: AppDetailContent.privacyPolicy.title())

    // *** Setup subviews ***
    let topStackView = UIStackView(
      arrangedSubviews: [termsOfServiceLink, separateLine(), privacyPolicyLink, separateLine()],
      axis: .vertical,
      spacing: 8
    )

    let versionTitle = infoLabel("Version:")
    versionInfoLabel = infoLabel()
    let versionInfoView = UIStackView(arrangedSubviews: [versionTitle, versionInfoLabel], axis: .horizontal, spacing: 8)

    let versionView = UIView()
    versionView.addSubview(versionInfoView)

    versionInfoView.snp.makeConstraints { (make) in
      make.top.equalToSuperview().offset(18)
    }

    whatNewLink = linkButton(title: "WHAT'S NEW?")
    appStoreReviewLink = linkButton(title: "APP STORE RATING & REVIEW")
    shareThisAppLink = linkButton(title: "SHARE THIS APP")

    let bottomStackView = UIStackView(
      arrangedSubviews: [whatNewLink, separateLine(), appStoreReviewLink, separateLine(), shareThisAppLink],
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
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20))
    }
  }

  fileprivate func linkButton(title: String) -> UIButton{
    let button = UIButton(type: .system)
    button.setTitle(title.uppercased(), for: .normal)
    button.setTitleColor(.mainBlueColor, for: .normal)
    button.titleLabel?.font = UIFont(name: "Avenir-Black", size: 15)
    button.contentHorizontalAlignment = .leading
    return button
  }

  fileprivate func separateLine() -> UIView {
    let sl = UIView()
    sl.backgroundColor = .rockBlue
    sl.snp.makeConstraints { (make) in make.height.equalTo(1) }
    return sl
  }

  fileprivate func infoLabel(_ text: String = "") -> UILabel {
    let label = UILabel(text: text)
    label.font = UIFont(name: "Courier", size: 14)
    return label
  }
}
