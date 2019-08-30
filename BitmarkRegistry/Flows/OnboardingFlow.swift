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
    case .viewTermsOfService:
      return navigateToViewTermsOfServiceScreen()
    case .viewPrivacyPolicy:
      return navigateToViewPrivacyPolicyScreen()
    case .userIsLoggedIn:
      return .end(forwardToParentFlowWithStep: BitmarkStep.dashboardIsRequired)
    default:
      return .none
    }
  }

  private func navigateToOnboardingScreen() -> FlowContributors {
    let onboardingVC = OnboardingViewController()
    rootViewController.isNavigationBarHidden = true
    rootViewController.setViewControllers([onboardingVC], animated: true)
    return .one(flowContributor: .contribute(withNextPresentable: onboardingVC,
                                             withNextStepper: onboardingVC))
  }

  fileprivate func navigateToLoginScreen() -> FlowContributors {
    let loginVC = LoginViewController()
    rootViewController.pushViewController(loginVC, animated: true)
    setupNewBackButton(in: loginVC.navigationItem)
    return .one(flowContributor: .contribute(withNextPresentable: loginVC,
                                             withNextStepper: loginVC))
  }

  fileprivate func navigateToTouchAuthenticationScreen() -> FlowContributors {
    let touchAuthenticationVC = TouchAuthenticationViewController()
    rootViewController.pushViewController(touchAuthenticationVC, animated: false)
    rootViewController.isNavigationBarHidden = true
    return .one(flowContributor: .contribute(withNextPresentable: touchAuthenticationVC,
                                             withNextStepper: touchAuthenticationVC))
  }

  fileprivate func navigateToViewTermsOfServiceScreen() -> FlowContributors {
    let appDetailContentVC = AppDetailContentViewController()
    appDetailContentVC.appDetailContent = .termsOfService
    rootViewController.pushViewController(appDetailContentVC)
    setupNewBackButton(in: appDetailContentVC.navigationItem)
    return .none
  }

  fileprivate func navigateToViewPrivacyPolicyScreen() -> FlowContributors {
    let appDetailContentVC = AppDetailContentViewController()
    appDetailContentVC.appDetailContent = .privacyPolicy
    rootViewController.pushViewController(appDetailContentVC)
    setupNewBackButton(in: appDetailContentVC.navigationItem)
    return .none
  }

  fileprivate func setupNewBackButton(in navigationItem: UINavigationItem) {
    rootViewController.isNavigationBarHidden = false

    let transparentNavBackButton = CommonUI.transparentNavBackButton()
    transparentNavBackButton.addTarget(self, action: #selector(tapBackNav), for: .touchUpInside)
    rootViewController.navigationBar.addSubview(transparentNavBackButton)
  }

  @objc func tapBackNav(_ sender: UIBarButtonItem) {
    rootViewController.popViewController(animated: true)
    rootViewController.navigationBar.removeSubviews()
    rootViewController.setNavigationBarHidden(true, animated: false)
  }
}
