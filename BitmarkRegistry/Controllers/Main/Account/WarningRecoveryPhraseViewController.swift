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
  let pageIcon: UIImageView = {
    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
    imageView.image = UIImage(named: "Warning")
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()

  let pageLabel: UILabel = {
    let label = CommonUI.pageTitleLabel(text: "WARNING!")
    label.textColor = .mainRedColor
    return label
  }()

  lazy var pageTitle: UIStackView = {
    return UIStackView(
      arrangedSubviews: [pageIcon, pageLabel],
      axis: .horizontal,
      spacing: 3,
      alignment: .leading,
      distribution: .fill
    )
  }()

  let warningTextView: UITextView = {
    let textView = UITextView()
    textView.font = UIFont(name: "Avenir", size: 17)
    textView.isUserInteractionEnabled = false
    textView.text =
      "Your recovery phrase is the only way to restore your Bitmark account if your phone is lost, stolen, broken, or upgraded.\n\n" +
      "We will show you a list of words to write down on a piece of paper and keep safe.\n\n" +
      "Make sure you are in a private location before writing down your recovery phrase."
    return textView
  }()

  lazy var writeDownRecoveryPhraseButton: UIButton = {
    let button = CommonUI.blueButton(title: "WRITE DOWN RECOVERY PHRASE")
    button.addAction(for: .touchUpInside, { [unowned self] in
      self.navigationController?.pushViewController(
        RecoveryPhraseViewController()
      )
    })
    return button
  }()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "RECOVERY PHRASE"
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
  }
}

// MARK: - Setup Views
extension WarningRecoveryPhraseViewController {
  private func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
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
