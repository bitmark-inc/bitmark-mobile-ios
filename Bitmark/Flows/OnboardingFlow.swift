//
//  OnboardingFlow.swift
//  Bitmark
//
//  Created by Thuyen Truong on 8/19/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxFlow

class OnboardingFlow: Flow {
  var root: Presentable {
    return self.rootViewController
  }
  var rootViewController: UINavigationController
  let transparentNavBackButton = CommonUI.transparentNavBackButton()

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
    case .askingBiometricAuthentication:
      return navigateToBiometricAuthenticationScreen()
    case .askingPasscodeAuthentication:
      return navigateToPasscodeAuthenticationScreen()
    case .askingiCloudSetting:
      return navigateToiCloudSettingScreen()
    case .viewTermsOfService:
      return navigateToViewTermsOfServiceScreen()
    case .viewPrivacyPolicy:
      return navigateToViewPrivacyPolicyScreen()
    case .iCloudSettingIsComplete:
      return navigate(to: BitmarkStep.onboardingIsComplete)
    case .onboardingIsComplete:
      return .end(forwardToParentFlowWithStep: BitmarkStep.dashboardIsRequired)
    case .appSuspension:
      return navigateToSuspendedScreen()
    default:
      return .none
    }
  }

  private func navigateToOnboardingScreen() -> FlowContributors {
    let onboardingVC = OnboardingViewController()
    rootViewController.isNavigationBarHidden = true
    rootViewController.setViewControllers([onboardingVC], animated: false)
    transparentNavBackButton.removeFromSuperview()
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

  fileprivate func navigateToBiometricAuthenticationScreen() -> FlowContributors {
    let biometricAuthenticationVC = BiometricAuthenticationViewController()
    rootViewController.pushViewController(biometricAuthenticationVC, animated: false)
    rootViewController.isNavigationBarHidden = true
    return .one(flowContributor: .contribute(withNextPresentable: biometricAuthenticationVC,
                                             withNextStepper: biometricAuthenticationVC))
  }

  fileprivate func navigateToPasscodeAuthenticationScreen() -> FlowContributors {
    let passcodeAuthenticationVC = PasscodeAuthenticationViewController()
    rootViewController.pushViewController(passcodeAuthenticationVC, animated: false)
    rootViewController.isNavigationBarHidden = true
    return .one(flowContributor: .contribute(withNextPresentable: passcodeAuthenticationVC,
                                             withNextStepper: passcodeAuthenticationVC))
  }

  fileprivate func navigateToiCloudSettingScreen() -> FlowContributors {
    let iCloudSettingVC = iCloudSettingViewController()
    rootViewController.pushViewController(iCloudSettingVC, animated: true)
    rootViewController.isNavigationBarHidden = true
    return .one(flowContributor: .contribute(withNextPresentable: iCloudSettingVC,
                                             withNextStepper: iCloudSettingVC))
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

  fileprivate func navigateToSuspendedScreen() -> FlowContributors {
    let appSuspensionVC = SuspendedViewController()
    rootViewController.viewControllers = [appSuspensionVC]
    return .none
  }

  fileprivate func setupNewBackButton(in navigationItem: UINavigationItem) {
    rootViewController.isNavigationBarHidden = false
    transparentNavBackButton.addTarget(self, action: #selector(tapBackNav), for: .touchUpInside)
    rootViewController.navigationBar.addSubview(transparentNavBackButton)
  }

  @objc func tapBackNav(_ sender: UIBarButtonItem) {
    rootViewController.popViewController(animated: true)
    transparentNavBackButton.removeFromSuperview()
    rootViewController.setNavigationBarHidden(true, animated: false)
  }
}
