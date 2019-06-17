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
  var closeButton: UIButton!
  var qrImage: UIImageView!
  var accountNumberLabel: UILabel!
  var shareButton: UIButton!
  var accountNumber: String!
  lazy var qrCode: UIImage? = {
    return QRCode(text: accountNumber).generateQRCode()
  }()

  // *** Override Properties in PanModal ***
  var panScrollable: UIScrollView? {
    return nil
  }

  var shortFormHeight: PanModalHeight {
    return .contentHeight(450)
  }

  var longFormHeight: PanModalHeight {
    return .contentHeight(450)
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
}

// MARK: - Setup Views
extension QRViewController {
  fileprivate func setupEvents() {
    closeButton.addAction(for: .touchUpInside) {
      self.dismiss(animated: true, completion: nil)
    }
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let title = CommonUI.pageTitleLabel(text: "RECEIVE PROPERTY")

    closeButton = UIButton()
    closeButton.setImage(UIImage(named: "close_icon_blue"), for: .normal)
    closeButton.snp.makeConstraints { (make) in
      make.width.height.equalTo(19)
    }

    let pageTitleView = UIStackView(arrangedSubviews: [title, closeButton])

    let separateLine = UIView()
    separateLine.backgroundColor = .black

    qrImage = UIImageView()

    accountNumberLabel = UILabel()
    accountNumberLabel.textAlignment = .center
    accountNumberLabel.numberOfLines = 0

    shareButton = UIButton(type: .system)
    shareButton.setTitle("SHARE", for: .normal)
    shareButton.setTitleColor(.white, for: .normal)
    shareButton.backgroundColor = .mainBlueColor

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
      make.top.equalTo(pageTitleView.snp.bottom).offset(20)
      make.height.equalTo(1)
      make.leading.trailing.equalToSuperview()
    }

    qrImage.snp.makeConstraints { (make) in
      make.top.equalTo(separateLine.snp.bottom).offset(30)
      make.width.height.equalTo(200)
      make.centerX.equalToSuperview()
    }

    accountNumberLabel.snp.makeConstraints { (make) in
      make.top.equalTo(qrImage.snp.bottom).offset(20)
      make.centerX.leading.trailing.equalToSuperview()
    }

    shareButton.snp.makeConstraints { (make) in
      make.top.equalTo(accountNumberLabel.snp.bottom).offset(30)
      make.width.equalTo(200)
      make.height.equalTo(45)
      make.centerX.equalToSuperview()
    }

    view.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaInsets)
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20))
    }
  }
}
