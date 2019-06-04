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
  func showSuccessAlert(message: String) {
    showInformedAlert(withTitle: "Success!", message: message)
  }

  func showErrorAlert(message: String) {
    showInformedAlert(withTitle: "Error", message: message)
  }

  func showConfirmationAlert(message: String, handler: @escaping () -> Void) {
    let alertView = UIAlertController(title: nil, message: Constant.Confirmation.deleteLabel, preferredStyle: .alert)
    let yesAction = UIAlertAction(title: "Yes", style: .default) { (_) in handler() }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alertView.addAction(cancelAction)
    alertView.addAction(yesAction)
    present(alertView, animated: true, completion: nil)
  }

  func showInformedAlert(withTitle title: String, message: String) {
    let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertView.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    present(alertView, animated: true, completion: nil)
  }

  func showAlertWithIndicator(message: String, handler: @escaping ()-> Void) -> UIAlertController {
    let alert = UIAlertController(title: nil, message: "", preferredStyle: .alert)
    let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    activityIndicator.isUserInteractionEnabled = false
    activityIndicator.startAnimating()
    activityIndicator.color = .black

    let messageLabel = UILabel()
    messageLabel.translatesAutoresizingMaskIntoConstraints = false
    messageLabel.text = message
    messageLabel.numberOfLines = 0
    messageLabel.font = UIFont(name: "SF Pro Text", size: 16)
    messageLabel.textAlignment = .center

    alert.view.addSubview(activityIndicator)
    alert.view.addSubview(messageLabel)

    activityIndicator.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor, constant: 0).isActive = true
    activityIndicator.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 25).isActive = true
    activityIndicator.bottomAnchor.constraint(equalTo: messageLabel.topAnchor, constant: -25).isActive = true
    messageLabel.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -20).isActive = true
    messageLabel.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor, constant: 0).isActive = true
    messageLabel.widthAnchor.constraint(equalToConstant: 212).isActive = true
    present(alert, animated: true) { handler() }
    return alert
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

  func updateLayoutWithKeyboard() {
    UIView.animate(withDuration: 0, delay: 0, options: .curveEaseOut, animations: {
      self.view.layoutIfNeeded()
    })
  }
}
