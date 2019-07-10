//
//  WarningRecoveryPhraseViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/10/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class WarningRecoveryPhraseViewController: UIViewController {

  // MARK: - Properties
  var writeDownRecoveryPhraseButton: UIButton!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "RECOVERY PHRASE"
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
    setupEvents()
  }
}

// MARK: - Setup Views/Events
extension WarningRecoveryPhraseViewController {
  fileprivate func setupEvents() {
    writeDownRecoveryPhraseButton.addAction(for: .touchUpInside, { [unowned self] in
      let recoveryPhraseVC = RecoveryPhraseViewController()
      recoveryPhraseVC.recoveryPhraseSource = RecoveryPhraseSource.testRecoveryPhrase
      self.navigationController?.pushViewController(recoveryPhraseVC)
    })
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let pageIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
    pageIcon.image = UIImage(named: "Warning")
    pageIcon.contentMode = .scaleAspectFit

    let pageLabel = CommonUI.pageTitleLabel(text: "WARNING!")
    pageLabel.textColor = .mainRedColor

    let pageTitle = UIStackView(
      arrangedSubviews: [pageIcon, pageLabel],
      axis: .horizontal,
      spacing: 3,
      alignment: .leading,
      distribution: .fill
    )

    let warningTextView = UITextView()
    warningTextView.font = UIFont(name: "Avenir", size: 17)
    warningTextView.isUserInteractionEnabled = true
    warningTextView.isEditable = false
    warningTextView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 20)
    warningTextView.text =
      "Your recovery phrase is the only way to restore your Bitmark account if your phone is lost, stolen, broken, or upgraded.\n\n" +
      "We will show you a list of words to write down on a piece of paper and keep safe.\n\n" +
      "Make sure you are in a private location before writing down your recovery phrase."

    let mainView = UIView()
    mainView.addSubview(pageTitle)
    mainView.addSubview(warningTextView)

    pageTitle.snp.makeConstraints { (make) in
      make.centerX.top.equalToSuperview()
    }

    warningTextView.snp.makeConstraints { (make) in
      make.top.equalTo(pageTitle.snp.bottom).offset(20)
      make.leading.trailing.bottom.equalToSuperview()
    }

    writeDownRecoveryPhraseButton = CommonUI.blueButton(title: "WRITE DOWN RECOVERY PHRASE")

    // *** Setup UI in view ***
    view.addSubview(mainView)
    view.addSubview(writeDownRecoveryPhraseButton)

    mainView.snp.makeConstraints { (make) in
      make.top.equalTo(view.safeAreaLayoutGuide).offset(38)
      make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
    }

    writeDownRecoveryPhraseButton.snp.makeConstraints { (make) in
      make.top.equalTo(mainView.snp.bottom).offset(-10)
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }
  }
}
