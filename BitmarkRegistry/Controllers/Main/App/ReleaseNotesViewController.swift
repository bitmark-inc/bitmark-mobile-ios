//
//  ReleaseNotesViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/30/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//  Reference: https://www.oodlestechnologies.com/blogs/Get-installation-Date-and-Version-of-the-App-In-Swift-3/
//

import UIKit
import Alamofire

class ReleaseNotesViewController: UIViewController {
  // MARK: - Properties
  let releaseNotesPath = "https://raw.githubusercontent.com/bitmark-inc/bitmark-mobile-ios/master/BitmarkRegistry/Supporting%20Files/ReleaseNotes.md"
  var versionInfoLabel: UILabel!
  var updatedDateLabel: UILabel!
  var releaseNotesContent: UILabel!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "RELEASE NOTES"
    navigationItem.setHidesBackButton(true, animated: false)
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeHandler))

    setupViews()
    loadData()
  }

  fileprivate func loadData() {
    if let appVersion = Bundle.main.infoDictionary?[Constant.InfoKey.kVersion] as? String {
      versionInfoLabel.text = "VERSION \(appVersion)"
    }

    if let pathToInfoPlist = Bundle.main.path(forResource: "Info", ofType: "plist"),
       let updateDate = try? FileManager.default.attributesOfItem(atPath: pathToInfoPlist)[.modificationDate] as? Date {
        let durationInDays = Calendar.current.dateComponents([.day], from: updateDate)
        updatedDateLabel.text = "\(durationInDays.day!)d ago"
    }

    Alamofire.request(releaseNotesPath).responseString { (response) in
      if let data = response.data, let utf8Data = String(data: data, encoding: .utf8) {
        self.releaseNotesContent.text = utf8Data
      }
    }
  }

  @objc func emailUs(_ sender: UIButton) {
    guard let supportEmail = sender.title(for: .normal),
          let url = URL(string: "mailto:\(supportEmail)") else { return }
      UIApplication.shared.open(url)
  }

  @objc func closeHandler(_ sender: UIButton) {
    navigationController?.popViewController(animated: true)
  }
}

// MARK: - Setup Views
extension ReleaseNotesViewController {
  private func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let separateLine = UIView()
    separateLine.backgroundColor = .mainBlueColor

    versionInfoLabel = CommonUI.pageTitleLabel()
    updatedDateLabel = UILabel()
    updatedDateLabel.font = UIFont(name: "Avenir", size: 14)
    updatedDateLabel.textColor = .dustyGray

    let titleStackView = UIStackView(arrangedSubviews: [versionInfoLabel, updatedDateLabel])

    releaseNotesContent = CommonUI.descriptionLabel(text: "___")

    let feedbackDescription = CommonUI.descriptionLabel(text:
      "We value your feedback, if you have ideas or suggestions on how to make our app even better, please email us at")
    let emailUsLink = UIButton(type: .system)

    emailUsLink.setTitle("support@bitmark.com", for: .normal)
    emailUsLink.addTarget(self, action: #selector(emailUs), for: .touchUpInside)

    let feedbackView = UIStackView(arrangedSubviews: [feedbackDescription, emailUsLink], axis: .vertical, spacing: -4, alignment: .leading)

    let mainView = UIView()

    mainView.addSubview(titleStackView)
    mainView.addSubview(releaseNotesContent)
    mainView.addSubview(feedbackView)

    titleStackView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    releaseNotesContent.snp.makeConstraints { (make) in
      make.top.equalTo(titleStackView.snp.bottom).offset(17)
      make.leading.trailing.equalToSuperview()
    }

    feedbackView.snp.makeConstraints { (make) in
      make.top.equalTo(releaseNotesContent.snp.bottom)
      make.leading.trailing.equalToSuperview()
    }

    // *** Setup UI in view ***
    view.addSubview(mainView)
    view.addSubview(separateLine) 

    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20))
    }

    separateLine.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      make.height.equalTo(1)
    }
  }
}
