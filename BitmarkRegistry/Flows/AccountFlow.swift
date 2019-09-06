//
//  AccountFlow.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/19/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import RxFlow
import RxCocoa

class AccountFlow: Flow {
  var root: Presentable {
    return self.rootViewController
  }
  private lazy var rootViewController: UINavigationController = {
    let navigationController = UINavigationController()
    navigationController.navigationBar.shadowImage = UIImage()
    navigationController.navigationBar.titleTextAttributes = [.font: UIFont(name: "Avenir-Black", size: 18)!]
    return navigationController
  }()
  let transparentNavBackButton = CommonUI.transparentNavBackButton()

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? BitmarkStep else { return .none }

    switch step {
    case .viewAccountDetails:
      return navigateToAccountScreen()
    case .viewWarningWriteDownRecoveryPhrase:
      return navigateToWarningWriteDownRecoveryPhraseScreen()
    case .viewRecoveryPhrase:
      return navigateToRecoveryPhraseScreen()
    case .viewRecoveryPhraseIsComplete:
      rootViewController.popToRootViewController(animated: true)
      return .none
    case .testRecoveryPhrase:
      return navigateToTestRecoveryPhraseScreen()
    case .testRecoveryPhraseIsComplete:
      rootViewController.popToRootViewController(animated: true)
      return .none
    case .viewWarningRemoveAccess:
      return navigateToWarningRemoveAccessScreen()
    case .viewRecoveryPhraseToRemoveAccess:
      return navigateToRecoveryPhraseToRemoveAccessScreen()
    case .testRecoveryPhraseToRemoveAccess:
      return navigateToTestRecoveryPhraseToRemoveAccessScreen()
    case .removeAccessIsComplete:
      return .end(forwardToParentFlowWithStep: BitmarkStep.dashboardIsComplete)
    case .viewAppDetails:
      return navigateToAppDetailsFlow()
    default:
      return .none
    }
  }

  fileprivate func navigateToAccountScreen() -> FlowContributors {
    let accountVC = AccountViewController()
    self.rootViewController.pushViewController(accountVC, animated: true)

    return .one(flowContributor: .contribute(withNextPresentable: accountVC, withNextStepper: accountVC))
  }

  fileprivate func navigateToWarningWriteDownRecoveryPhraseScreen() -> FlowContributors {
    let warningWriteDownRecoveryPhraseVC = WarningRecoveryPhraseViewController()
    self.rootViewController.pushViewController(warningWriteDownRecoveryPhraseVC, animated: true)

    return .one(flowContributor: .contribute(withNextPresentable: warningWriteDownRecoveryPhraseVC, withNextStepper: warningWriteDownRecoveryPhraseVC))
  }

  fileprivate func navigateToRecoveryPhraseScreen() -> FlowContributors {
    let recoveryPhraseVC = RecoveryPhraseViewController()
    recoveryPhraseVC.title = "RecoveryPhrase".localized().localizedUppercase
    recoveryPhraseVC.recoveryPhraseSource = .testRecoveryPhrase
    rootViewController.pushViewController(recoveryPhraseVC)

    return .one(flowContributor: .contribute(withNextPresentable: recoveryPhraseVC, withNextStepper: recoveryPhraseVC))
  }

  fileprivate func navigateToTestRecoveryPhraseScreen() -> FlowContributors {
    let testRecoveryPhraseVC = TestRecoveryPhraseViewController()
    testRecoveryPhraseVC.title = "TestRecoveryPhrase".localized().localizedUppercase
    testRecoveryPhraseVC.recoveryPhraseSource = .testRecoveryPhrase
    rootViewController.pushViewController(testRecoveryPhraseVC)
    setupNewBackButtonToRoot(in: testRecoveryPhraseVC.navigationItem)

    return .one(flowContributor: .contribute(withNextPresentable: testRecoveryPhraseVC, withNextStepper: testRecoveryPhraseVC))
  }

  fileprivate func navigateToWarningRemoveAccessScreen() -> FlowContributors {
    let warningRemoveAccessVC = WarningRemoveAccessViewController()
    self.rootViewController.pushViewController(warningRemoveAccessVC, animated: true)

    return .one(flowContributor: .contribute(withNextPresentable: warningRemoveAccessVC, withNextStepper: warningRemoveAccessVC))
  }

  fileprivate func navigateToRecoveryPhraseToRemoveAccessScreen() -> FlowContributors {
    let recoveryPhraseVC = RecoveryPhraseViewController()
    recoveryPhraseVC.recoveryPhraseSource = .removeAccess
    recoveryPhraseVC.title = "WriteDownRecoveryPhrase".localized().localizedUppercase
    rootViewController.pushViewController(recoveryPhraseVC)

    return .one(flowContributor: .contribute(withNextPresentable: recoveryPhraseVC, withNextStepper: recoveryPhraseVC))
  }

  fileprivate func navigateToTestRecoveryPhraseToRemoveAccessScreen() -> FlowContributors {
    let testRecoveryPhraseVC = TestRecoveryPhraseViewController()
    testRecoveryPhraseVC.title = "RecoveryPhraseSignOut".localized().localizedUppercase
    testRecoveryPhraseVC.recoveryPhraseSource = .removeAccess
    rootViewController.pushViewController(testRecoveryPhraseVC)

    setupNewBackButtonToRoot(in: testRecoveryPhraseVC.navigationItem)
    return .one(flowContributor: .contribute(withNextPresentable: testRecoveryPhraseVC, withNextStepper: testRecoveryPhraseVC))
  }

  fileprivate func navigateToAppDetailsFlow() -> FlowContributors {
    let appDetailsFlow = AppDetailsFlow(rootViewController: rootViewController)
    return .one(flowContributor: .contribute(withNextPresentable: appDetailsFlow,
                                             withNextStepper: OneStepper(withSingleStep: BitmarkStep.viewAppDetails)))
  }

  fileprivate func setupNewBackButtonToRoot(in navigationItem: UINavigationItem) {
    rootViewController.isNavigationBarHidden = false
    transparentNavBackButton.addTarget(self, action: #selector(tapBackRootNav), for: .touchUpInside)
    rootViewController.navigationBar.addSubview(transparentNavBackButton)
  }

  @objc func tapBackRootNav(_ sender: UIBarButtonItem) {
    rootViewController.popToRootViewController(animated: true)
    transparentNavBackButton.removeFromSuperview()
  }
}

class AccountStepper: Stepper {
  var steps = PublishRelay<Step>()

  var initialStep: Step {
    return BitmarkStep.viewAccountDetails
  }
}
