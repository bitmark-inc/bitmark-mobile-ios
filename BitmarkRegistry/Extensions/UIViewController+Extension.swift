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

  func showConfirmationAlert(message: String, handler: @escaping () -> Void) {
    let alertController = UIAlertController(title: "", message: message, defaultActionButtonTitle: "Cancel")
    alertController.addAction(title: "Yes", style: .default, isEnabled: true, handler: {_ in handler() })
    alertController.show()
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
