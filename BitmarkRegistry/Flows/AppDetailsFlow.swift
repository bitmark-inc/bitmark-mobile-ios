//
//  AppDetailsFlow.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/20/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import RxFlow

class AppDetailsFlow: Flow {
  var root: Presentable {
    return self.rootViewController
  }
  var rootViewController: UINavigationController

  init(rootViewController: UINavigationController) {
    self.rootViewController = rootViewController
  }

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? BitmarkStep else { return .none }

    switch step {
    case .viewAppDetails:
      return navigateToAppDetailsScreen()
    case .viewTermsOfService:
      return navigateToViewTermsOfServiceScreen()
    case .viewPrivacyPolicy:
      return navigateToViewPrivacyPolicyScreen()
    case .viewReleaseNotes:
      return navigateToViewReleaseNotesScreen()
    case .viewReleaseNotesIsComplete:
      rootViewController.popViewController(animated: true)
      return .none
    default:
      return .none
    }
  }

  fileprivate func navigateToAppDetailsScreen() -> FlowContributors {
    let appDetailsVC = AppDetailViewController()
    rootViewController.pushViewController(appDetailsVC)
    return .one(flowContributor: .contribute(withNextPresentable: appDetailsVC, withNextStepper: appDetailsVC))
  }

  fileprivate func navigateToViewTermsOfServiceScreen() -> FlowContributors {
    let appDetailContentVC = AppDetailContentViewController()
    appDetailContentVC.appDetailContent = .termsOfService
    rootViewController.pushViewController(appDetailContentVC)
    return .none
  }

  fileprivate func navigateToViewPrivacyPolicyScreen() -> FlowContributors {
    let appDetailContentVC = AppDetailContentViewController()
    appDetailContentVC.appDetailContent = .privacyPolicy
    rootViewController.pushViewController(appDetailContentVC)
    return .none
  }

  fileprivate func navigateToViewReleaseNotesScreen() -> FlowContributors {
    let releaseNotesContentVC = ReleaseNotesViewController()
    releaseNotesContentVC.hidesBottomBarWhenPushed = true
    rootViewController.pushViewController(releaseNotesContentVC)
    return .one(flowContributor: .contribute(withNextPresentable: releaseNotesContentVC, withNextStepper: releaseNotesContentVC))
  }
}
