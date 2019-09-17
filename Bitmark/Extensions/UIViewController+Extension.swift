//
//  UIViewController+Extension.swift
//  Bitmark
//
//  Created by Thuyen Truong on 5/29/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import Photos
import RxSwift

extension UIViewController {

  // MARK: - Alert
  func showErrorAlert(message: String) {
    showAlert(title: "Error".localized(), message: message, buttonTitles: ["OK".localized()])
  }

  func showSuccessAlert(message: String, handler: @escaping () -> Void) {
    let alertController = UIAlertController(title: "Success!".localized(), message: message, preferredStyle: .alert)
    alertController.addAction(title: "OK".localized(), style: .default, handler: {_ in handler() })
    alertController.show()
  }

  func showQuickMessageAlert(title: String? = nil, message: String, handler: @escaping () -> Void) {
    let alertController = UIAlertController(title: nil, message: "", preferredStyle: .alert)

    let successImageView = UIImageView(image: UIImage(named: "alert-success-icon"))
    let messageLabel = CommonUI.alertMessageLabel(text: message)

    alertController.view.addSubview(successImageView)
    var titleLabel: UILabel?
    if let title = title {
      titleLabel = CommonUI.alertTitleLabel(text: title)
      guard let titleLabel = titleLabel else { return }
      alertController.view.addSubview(titleLabel)

      titleLabel.snp.makeConstraints { (make) in
        make.top.equalTo(successImageView.snp.bottom).offset(10)
        make.centerX.equalToSuperview()
      }
    }

    alertController.view.addSubview(messageLabel)

    successImageView.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.top.equalToSuperview().offset(45)
    }

    messageLabel.snp.makeConstraints { (make) in
      let messageCompanion: UIView
      let messageWidth: CGFloat
      if let titleLabel = titleLabel {
        messageCompanion = titleLabel
        messageWidth = 250
      } else {
        messageCompanion = successImageView
        messageWidth = 212
      }
      make.top.equalTo(messageCompanion.snp.bottom).offset(20)
      make.bottom.equalToSuperview().offset(-30)
      make.centerX.equalToSuperview()
      make.width.equalTo(messageWidth)
    }

    alertController.show()

    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
      alertController.dismiss(animated: true, completion: handler)
    }
  }

  func showConfirmationAlert(message: String, handler: @escaping () -> Void) {
    let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
    alertController.addAction(title: "No".localized(), style: .cancel, handler: nil)
    alertController.addAction(title: "Yes".localized(), style: .default, handler: {_ in handler() })
    present(alertController, animated: true, completion: nil)
  }

  func showIndicatorAlert(message: String, handler: @escaping (_ selfAlert: UIAlertController) -> Void) {
    let alertController = UIAlertController(title: nil, message: "", preferredStyle: .alert)
    let activityIndicator = CommonUI.appActivityIndicator()
    activityIndicator.startAnimating()

    let messageLabel = CommonUI.alertMessageLabel(text: message)

    alertController.view.addSubview(activityIndicator)
    alertController.view.addSubview(messageLabel)

    activityIndicator.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.top.equalToSuperview().offset(45)
    }

    messageLabel.snp.makeConstraints { (make) in
      make.top.equalTo(activityIndicator.snp.bottom).offset(25)
      make.bottom.equalToSuperview().offset(-20)
      make.centerX.equalToSuperview()
      make.width.equalTo(230)
    }

    alertController.show { handler(alertController) }
  }

  // MARK: - Support Functions
  func askForPhotosPermission(handler: @escaping (PHAuthorizationStatus) -> Void ) {
    let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()

    switch photoAuthorizationStatus {
    case .notDetermined:
      PHPhotoLibrary.requestAuthorization { (newStatus) in
        DispatchQueue.main.async { handler(newStatus) }
      }
    case .authorized:
      handler(photoAuthorizationStatus)
    default:
      let alertController = UIAlertController(
        title: "permissionPhoto_title".localized(tableName: "Error"),
        message: "permissionPhoto_message".localized(tableName: "Error"),
        preferredStyle: .alert
      )
      alertController.addAction(
        title: "EnableAccess".localized(),
        style: .default, handler: openAppSettings
      )
      alertController.show()
    }
  }

  @objc func openAppSettings(_ sender: UIAlertAction) {
    guard let url = URL.init(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }

  func requireAuthenticationForAction(_ disposeBag: DisposeBag, action: @escaping () -> Void) {
    guard UserSetting.shared.getTouchFaceIdSetting() else {
      action()
      return
    }

    BiometricAuth().authorizeAccess()
      .observeOn(MainScheduler.instance)
      .subscribe(onCompleted: {
        action()
      })
     .disposed(by: disposeBag)
  }
}
