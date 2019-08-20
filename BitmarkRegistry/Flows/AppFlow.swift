//
//  AppFlow.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/19/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import RxFlow
import RxSwift
import RxCocoa

class AppFlow: Flow {
  var root: Presentable {
    return self.rootViewController
  }

  private lazy var rootViewController: UINavigationController = {
    let viewController = UINavigationController()
    viewController.setNavigationBarHidden(true, animated: false)
    return viewController
  }()

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? BitmarkStep else { return .none }

    switch step {
    case .appNavigation:
      return navigateToAppNavigationScreen()
    case .dashboardIsRequired:
      return navigateToDashboardScreen()
    case .onboardingIsRequired:
      return navigateToOnboardingScreen()
    default:
      return .none
    }
  }

  fileprivate func navigateToAppNavigationScreen() -> FlowContributors {
    let appNavigationVC = AppNavigationViewController()
    self.rootViewController.pushViewController(appNavigationVC, animated: false)

    return .one(flowContributor: .contribute(withNextPresentable: appNavigationVC, withNextStepper: appNavigationVC))
  }

  private func navigateToDashboardScreen() -> FlowContributors {
    let dashboardFlow = DashboardFlow()
    Flows.whenReady(flow1: dashboardFlow) { [unowned self] root in
      self.rootViewController.setViewControllers([root], animated: true)
    }

    return .one(flowContributor: .contribute(withNextPresentable: dashboardFlow,
                                             withNextStepper: OneStepper(withSingleStep: BitmarkStep.dashboardIsRequired)))
  }

  private func navigateToOnboardingScreen() -> FlowContributors {
    let onboardingFlow = OnboardingFlow(rootViewController: rootViewController)
    return .one(flowContributor: .contribute(withNextPresentable: onboardingFlow,
                                             withNextStepper: OneStepper(withSingleStep: BitmarkStep.accountIsRequired)))
  }
}

class AppStepper: Stepper {
  var steps = PublishRelay<Step>()

  var initialStep: Step {
    return BitmarkStep.appNavigation
  }
}


