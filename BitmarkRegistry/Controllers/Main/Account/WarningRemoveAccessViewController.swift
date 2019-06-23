//
//  WarningRemoveAccessViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/23/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class WarningRemoveAccessViewController: UIViewController {

  // MARK: - Properties
  var writeDownRecoveryPhraseButton: UIButton!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "REMOVE ACCESS"
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
    setupEvents()
  }
}

// MARK: - Setup Views/Events
extension WarningRemoveAccessViewController {
  fileprivate func setupEvents() {
    writeDownRecoveryPhraseButton.addAction(for: .touchUpInside, { [unowned self] in
      let recoveryPhraseVC = RecoveryPhraseViewController()
      recoveryPhraseVC.recoveryPhraseSource = RecoveryPhraseSource.RemoveAccess
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
    warningTextView.isUserInteractionEnabled = false
    warningTextView.text =
      "Your recovery phrase is the only way to access your Bitmark account after signing out. If you have not already written down your recovery phrase, you must do so now or you will be permanently lose access to your account and lose ownership of all your digital properties.\n\n" +
      "Your recovery phrase is a list of 24 words to write on a piece of paper and keep safe. Make sure you are in a private location when you write it down.\n\n" +
      "This will completely remove access to your account on this device. Regular data bitmarking and data donations will be paused until you sign back in with your recovery phrase."

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
      make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
      make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-20)
    }

    writeDownRecoveryPhraseButton.snp.makeConstraints { (make) in
      make.top.equalTo(mainView.snp.bottom).offset(-10)
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }
  }
}
