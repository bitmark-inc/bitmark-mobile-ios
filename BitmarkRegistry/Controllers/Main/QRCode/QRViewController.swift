//
//  QRViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/18/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import PanModal

class QRViewController: UIViewController, PanModalPresentable {

  // MARK: - Properties
  var accountNumber: String!
  lazy var qrCode: UIImage? = {
    return QRCode(text: accountNumber).generateQRCode()
  }()

  var closeButton: UIButton!
  var qrImage: UIImageView!
  var accountNumberLabel: UILabel!
  var shareButton: UIButton!

  // *** Override Properties in PanModal ***
  var panScrollable: UIScrollView? {
    return nil
  }

  var shortFormHeight: PanModalHeight {
    return .contentHeight(470)
  }

  var longFormHeight: PanModalHeight {
    return .contentHeight(470)
  }

  var cornerRadius: CGFloat = 0.0

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    setupViews()
    setupEvents()

    loadData()
  }

  // MARK: - Data Handlers
  private func loadData() {
    qrImage.image = qrCode
    accountNumberLabel.text = accountNumber
  }

  // MARK: - Handlers
  @objc func tapToShare(_ sender: UIButton) {
    guard let accountNumber = accountNumber, let qrCode = qrCode else { return }
    let activityVC = UIActivityViewController(activityItems: [accountNumber, qrCode], applicationActivities: [])
    present(activityVC, animated: true)
  }
}

// MARK: - Setup Views/Events
extension QRViewController {
  fileprivate func setupEvents() {
    closeButton.addAction(for: .touchUpInside) {
      self.dismiss(animated: true, completion: nil)
    }

    shareButton.addTarget(self, action: #selector(tapToShare), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let title = CommonUI.pageTitleLabel(text: "RECEIVE PROPERTY")

    closeButton = UIButton(type: .system, imageName: "close-icon-blue")
    closeButton.snp.makeConstraints { (make) in
      make.width.height.equalTo(21)
    }

    let pageTitleView = UIStackView(arrangedSubviews: [title, closeButton])

    let separateLine = UIView()
    separateLine.backgroundColor = .rockBlue

    qrImage = UIImageView()
    setupAccountNumberLabel()
    shareButton = setupShareButton()

    // *** Setup UI in view ***
    let mainView = UIView()
    mainView.addSubview(pageTitleView)
    mainView.addSubview(separateLine)
    mainView.addSubview(qrImage)
    mainView.addSubview(accountNumberLabel)
    mainView.addSubview(shareButton)

    pageTitleView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    separateLine.snp.makeConstraints { (make) in
      make.top.equalTo(pageTitleView.snp.bottom).offset(15)
      make.height.equalTo(1)
      make.leading.trailing.equalToSuperview()
    }

    qrImage.snp.makeConstraints { (make) in
      make.top.equalTo(separateLine.snp.bottom).offset(50)
      make.width.height.equalTo(200)
      make.centerX.equalToSuperview()
    }

    accountNumberLabel.snp.makeConstraints { (make) in
      make.top.equalTo(qrImage.snp.bottom).offset(27)
      make.centerX.leading.trailing.equalToSuperview()
    }

    shareButton.snp.makeConstraints { (make) in
      make.top.equalTo(accountNumberLabel.snp.bottom).offset(50)
      make.width.equalTo(200)
      make.height.equalTo(45)
      make.centerX.equalToSuperview()
    }

    view.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaInsets)
          .inset(UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
    }
  }

  fileprivate func setupShareButton() -> UIButton {
    let shareButton = UIButton(type: .system, imageName: "white-share-icon")
    shareButton.titleLabel?.font = UIFont(name: "Avenir-Black", size: 17)
    shareButton.setTitle("SHARE", for: .normal)
    shareButton.setTitleColor(.white, for: .normal)
    shareButton.tintColor = .white
    shareButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 13)
    shareButton.backgroundColor = .mainBlueColor
    return shareButton
  }

  fileprivate func setupAccountNumberLabel() {
    accountNumberLabel = UILabel()
    accountNumberLabel.font = UIFont(name: "Courier", size: 11)
    accountNumberLabel.textAlignment = .center
    accountNumberLabel.numberOfLines = 0
  }
}
