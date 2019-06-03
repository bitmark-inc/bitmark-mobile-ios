//
//  KeyboardObserver.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/1/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

protocol KeyboardObserver {
  func registerForKeyboardNotifications() -> [NSObjectProtocol]
  func keyboardWillBeShow(notification: Notification)
  func keyboardWillBeHide(notification: Notification)
}

extension KeyboardObserver {
  func registerForKeyboardNotifications() -> [NSObjectProtocol] {
    return [
      NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: OperationQueue.main, using: keyboardWillBeShow(notification:)),
      NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main, using: keyboardWillBeHide(notification:))]
  }
}
