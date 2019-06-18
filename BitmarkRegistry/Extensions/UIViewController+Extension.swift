//
//  UIViewController+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/29/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

extension UIViewController {

  // MARK: - Alert
  func showErrorAlert(message: String) {
    showAlert(title: "Error", message: message)
  }
}
