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
    showInformedAlert(withTitle: "Error", message: message)
  }

  func showInformedAlert(withTitle title: String, message: String) {
    let alertView = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertView.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    present(alertView, animated: true, completion: nil)
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
