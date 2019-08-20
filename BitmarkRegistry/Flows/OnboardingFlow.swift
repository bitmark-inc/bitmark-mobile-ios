//
//  OnboardingFlow.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/19/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import RxFlow

class OnboardingFlow: Flow {
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
    case .accountIsRequired:
      return navigateToOnboardingScreen()
    case .testLogin:
      return navigateToLoginScreen()
    case .askingTouchFaceIdAuthentication:
      return navigateToTouchAuthenticationScreen()
    case .userIsLoggedIn:
      return .end(forwardToParentFlowWithStep: BitmarkStep.dashboardIsRequired)
    default:
      return .none
    }
  }

  private func navigateToOnboardingScreen() -> FlowContributors {
    let onboardingVC = OnboardingViewController()
    self.rootViewController.isNavigationBarHidden = true
    self.rootViewController.pushViewController(onboardingVC, animated: false)
    return .one(flowContributor: .contribute(withNextPresentable: onboardingVC,
                                             withNextStepper: onboardingVC))
  }

  fileprivate func navigateToLoginScreen() -> FlowContributors {
    let loginVC = LoginViewController()
    self.rootViewController.pushViewController(loginVC, animated: true)
    self.rootViewController.isNavigationBarHidden = false
    self.rootViewController.navigationItem.backBarButtonItem = UIBarButtonItem()
    return .one(flowContributor: .contribute(withNextPresentable: loginVC,
                                             withNextStepper: loginVC))
  }

  fileprivate func navigateToTouchAuthenticationScreen() -> FlowContributors {
    let touchAuthenticationVC = TouchAuthenticationViewController()
    self.rootViewController.pushViewController(touchAuthenticationVC, animated: false)
    return .one(flowContributor: .contribute(withNextPresentable: touchAuthenticationVC,
                                             withNextStepper: touchAuthenticationVC))
  }
}
