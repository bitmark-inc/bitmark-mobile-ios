//
//  NotificationService.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/1/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class NotificationService {
  static let shared = NotificationService()

  func addNotification(in weakObservers: inout NSPointerArray, with observer: NSObjectProtocol) {
    let pointer = Unmanaged.passUnretained(observer).toOpaque()
    weakObservers.addPointer(pointer)
  }

  func removeNotifications(_ weakObservers: NSPointerArray) {
    for observer in weakObservers.allObjects {
      NotificationCenter.default.removeObserver(observer)
    }
  }
}
