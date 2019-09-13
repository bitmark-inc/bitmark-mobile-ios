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
import RxFlow
import RxCocoa

class ReleaseNotesViewController: UIViewController, Stepper {
  var steps = PublishRelay<Step>()

  // MARK: - Properties
  let releaseNotesPath: String = {
    let releaseNotesFile = (NSLocale.preferredLanguages[0].range(of: "zh") != nil) ? "ReleaseNotes.zh.md" : "ReleaseNotes.md"
    return "https://raw.githubusercontent.com/bitmark-inc/bitmark-mobile-ios/master/BitmarkRegistry/Supporting%20Files/" + releaseNotesFile
  }()
  var versionInfoLabel: UILabel!
  var updatedDateLabel: UILabel!
  var releaseNotesContent: UILabel!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "appDetails_releaseNotes".localized(tableName: "Phrase").localizedUppercase
    navigationItem.setHidesBackButton(true, animated: false)
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close".localized(), style: .plain, target: self, action: #selector(closeHandler))

    setupViews()
    loadData()
  }

  fileprivate func loadData() {
    if let appVersion = Bundle.main.infoDictionary?[Constant.InfoKey.kVersion] as? String {
      versionInfoLabel.text = String(format: "appDetails_versionApp".localized(tableName: "Phrase"), appVersion)
    }

    if let pathToInfoPlist = Bundle.main.path(forResource: "Info", ofType: "plist"),
       let updateDate = try? FileManager.default.attributesOfItem(atPath: pathToInfoPlist)[.modificationDate] as? Date {
        let durationInDays = Calendar.current.dateComponents([.day], from: updateDate)
        updatedDateLabel.text = String(format: "dAgo".localized(), durationInDays.day!)
    }

    Alamofire.request(releaseNotesPath).responseString { (response) in
      if let data = response.data, let utf8Data = String(data: data, encoding: .utf8) {
        self.releaseNotesContent.text = utf8Data
      }
    }
  }

  @objc func closeHandler(_ sender: UIButton) {
    steps.accept(BitmarkStep.viewReleaseNotesIsComplete)
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

    let feedbackSupportMessage = "appDetails_supportMessage".localized(tableName: "Phrase")
    let supportEmail = "support@bitmark.com"
    let feedbackDescription = NSMutableAttributedString(
      string: feedbackSupportMessage + " " +  supportEmail,
      attributes: [NSAttributedString.Key.font: UIFont(name: "Avenir", size: 17)!]
    )
    feedbackDescription.addAttribute(.link, value: URL(string: "mailto:\(supportEmail)")!, range: NSRange(location: feedbackSupportMessage.count + 1, length: supportEmail.count))

    let feedbackTextView = UITextView()
    feedbackTextView.attributedText = feedbackDescription
    feedbackTextView.isEditable = false

    let mainView = UIView()

    mainView.addSubview(titleStackView)
    mainView.addSubview(releaseNotesContent)
    mainView.addSubview(feedbackTextView)

    titleStackView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    releaseNotesContent.snp.makeConstraints { (make) in
      make.top.equalTo(titleStackView.snp.bottom).offset(17)
      make.leading.trailing.equalToSuperview()
    }

    feedbackTextView.snp.makeConstraints { (make) in
      make.top.equalTo(releaseNotesContent.snp.bottom).offset(-10)
      make.leading.trailing.bottom.equalToSuperview()
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
