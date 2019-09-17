//
//  WarningRemoveAccessViewController.swift
//  Bitmark
//
//  Created by Thuyen Truong on 6/23/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxFlow
import RxCocoa

class WarningRemoveAccessViewController: UIViewController, Stepper {
  var steps = PublishRelay<Step>()

  // MARK: - Properties
  var writeDownRecoveryPhraseButton: UIButton!
  let disposeBag = DisposeBag()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "warningRemoveAccess_Title".localized(tableName: "Phrase").localizedUppercase
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
  }

  @objc func gotoRecoveryPhraseVC() {
    requireAuthenticationForAction(disposeBag) { [weak self] in
      self?.steps.accept(BitmarkStep.viewRecoveryPhraseToRemoveAccess)
    }
  }
}

// MARK: - Setup Views/Events
extension WarningRemoveAccessViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let pageIcon = UIImageView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
    pageIcon.image = UIImage(named: "Warning")
    pageIcon.contentMode = .scaleAspectFit

    let pageLabel = CommonUI.pageTitleLabel(text: "Warning!".localized().localizedUppercase)
    pageLabel.textColor = .mainRedColor

    let pageTitle = UIStackView(
      arrangedSubviews: [pageIcon, pageLabel],
      axis: .horizontal,
      spacing: 3,
      alignment: .leading,
      distribution: .fill
    )

    let warningTextView = UITextView()
    warningTextView.font = UIFont(name: "Avenir", size: 16)
    warningTextView.isUserInteractionEnabled = true
    warningTextView.isEditable = false
    warningTextView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 15, right: 20)
    warningTextView.text = "warningRemoveAccess_Description".localized(tableName: "Phrase")

    let mainView = UIView()
    mainView.addSubview(pageTitle)
    mainView.addSubview(warningTextView)

    pageTitle.snp.makeConstraints { (make) in
      make.centerX.top.equalToSuperview()
    }

    warningTextView.snp.makeConstraints { (make) in
      make.top.equalTo(pageTitle.snp.bottom)
      make.leading.trailing.bottom.equalToSuperview()
    }

    writeDownRecoveryPhraseButton = CommonUI.blueButton(title: "WriteDownRecoveryPhrase".localized().localizedUppercase)
    writeDownRecoveryPhraseButton.addTarget(self, action: #selector(gotoRecoveryPhraseVC), for: .touchUpInside)

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
