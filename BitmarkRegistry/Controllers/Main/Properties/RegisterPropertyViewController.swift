//
//  RegisterPropertyViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class RegisterPropertyViewController: UIViewController {

  // MARK: - Properties
  lazy var registerByPhotoButton: UIButton = {
    let button = registerButton(by: "PHOTOS")
    return button
  }()

  lazy var registerByFileButton: UIButton = {
    let button = registerButton(by: "FILES")
    return button
  }()

  let descriptionLabel = CommonUI.descriptionLabel(text: "Property rights are registered on Bitmark through the creation of an asset record followed by an issue record. Once an asset has been issued, transferring it simply requires taking advantage of the blockchain's standard attributes.").lineHeightMultiple(1.2)

  lazy var registerSelectionView: UIStackView = {
    let registerButtons: [UIButton] = [registerByPhotoButton, registerByFileButton]

    let stackView = UIStackView(
      arrangedSubviews: registerButtons,
      axis: .vertical,
      spacing: 10.0,
      alignment: .leading,
      distribution: .fill
    )

    for registerButton in registerButtons {
      registerButton.snp.makeConstraints { $0.width.equalToSuperview() }
    }

    return stackView
  }()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "REGISTER"
    setupViews()
  }
}

// MARK: - Setup Views
extension RegisterPropertyViewController {
  private func setupViews() {
    view.backgroundColor = .white

    // *** Setup UI in view ***
    view.addSubview(registerSelectionView)
    view.addSubview(descriptionLabel)

    registerSelectionView.snp.makeConstraints { (make) in
      make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
      make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
    }

    descriptionLabel.snp.makeConstraints { (make) in
      make.top.equalTo(registerSelectionView.snp.bottom).offset(18)
      make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
      make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-20)
    }
  }

  private func registerButton(by text: String) -> UIButton{
    let button = UIButton()
    button.backgroundColor = .aliceBlue
    button.setTitle(text, for: .normal)
    button.setTitleColor(.mainBlueColor, for: .normal)
    button.titleLabel?.font = UIFont(name: "Avenir-Black", size: 16)
    button.contentHorizontalAlignment = .left
    button.titleEdgeInsets.left = 20.0
    button.snp.makeConstraints { $0.height.equalTo(45) }
    return button
  }
}
