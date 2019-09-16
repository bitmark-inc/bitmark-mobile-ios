//
//  AppDelegate+PushNotification.swift
//  BitmarkRegistry
//
//  Created by Anh Nguyen on 8/9/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import UserNotifications
import RealmSwift

extension AppDelegate: UNUserNotificationCenterDelegate {

  func userNotificationCenter(_ center: UNUserNotificationCenter,
              didReceive response: UNNotificationResponse,
              withCompletionHandler completionHandler:
                 @escaping () -> Void) {
    guard let userInfo = response.notification.request.content.userInfo as? [String: AnyObject] else {
      return
    }

    self.handleNotificationInfo(userInfo, withCompletionHandler: completionHandler)
  }

  func userNotificationCenter(_ center: UNUserNotificationCenter,
           willPresent notification: UNNotification,
           withCompletionHandler completionHandler:
              @escaping (UNNotificationPresentationOptions) -> Void) {
    // Trigger sync data when receiving notification
    try? BitmarkStorage.shared().syncData()

    // Show notification
    completionHandler(.alert)
    return
  }

  private func handleNotificationInfo(_ userInfo: [String: AnyObject],
                                      withCompletionHandler completionHandler: @escaping () -> Void) {
    defer { completionHandler() }
    // Detect type of notification
    guard let notificationName = userInfo["name"] as? String else {
      // Not a notification from mobile server, report error and ignore the action
      return
    }

    switch notificationName {
    case "transfer_confirmed_receiver":
      guard let bitmarkId = userInfo["bitmark_id"] as? String else {
        return
      }

      // Detect current screen
      ScreenRouteService.routeToBitmarkDetail(bitmarkID: bitmarkId, completionHandler: nil)
    default:
      ErrorReporting.report(message: "Unhandled notification: " + notificationName)
      return
    }
  }

}
