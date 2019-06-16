//
//  UIViewController+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import Photos

extension UIViewController {

  // MARK: - Alert
  func showErrorAlert(message: String) {
    showAlert(title: "Error", message: message)
  }

  func showSuccessAlert(message: String) {
    showAlert(title: "Success!", message: message)
  }

  func showConfirmationAlert(message: String, handler: @escaping () -> Void) {
    let alertController = UIAlertController(title: "", message: message, defaultActionButtonTitle: "Cancel")
    alertController.addAction(title: "Yes", style: .default, isEnabled: true, handler: {_ in handler() })
    alertController.show()
  }

  func showIndicatorAlert(message: String, handler: @escaping () -> Void) -> UIAlertController {
    let alertController = UIAlertController(title: nil, message: "", preferredStyle: .alert)
    let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    activityIndicator.color = .black
    activityIndicator.startAnimating()

    let messageLabel = UILabel()
    messageLabel.text = message
    messageLabel.numberOfLines = 0
    messageLabel.font = UIFont(name: "SF Pro Text", size: 16)
    messageLabel.textAlignment = .center

    alertController.view.addSubview(activityIndicator)
    alertController.view.addSubview(messageLabel)

    activityIndicator.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.top.equalToSuperview().offset(25)
    }

    messageLabel.snp.makeConstraints { (make) in
      make.top.equalTo(activityIndicator.snp.bottom).offset(25)
      make.bottom.equalToSuperview().offset(-20)
      make.centerX.equalToSuperview()
      make.width.equalTo(212)
    }

    alertController.show { handler() }
    return alertController
  }

  // MARK: - Support Functions
  func askForPhotosPermission(handler: @escaping (PHAuthorizationStatus) -> Void ) {
    let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
    if photoAuthorizationStatus == .notDetermined {
      PHPhotoLibrary.requestAuthorization { (newStatus) in
        DispatchQueue.main.async { handler(newStatus) }
      }
    } else {
      handler(photoAuthorizationStatus)
    }
  }
}
