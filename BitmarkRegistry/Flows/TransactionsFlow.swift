//
//  TransactionsFlow.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/19/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import RxFlow
import RxCocoa
import Alamofire

class TransactionsFlow: Flow {
  var root: Presentable {
    return self.rootViewController
  }
  private lazy var rootViewController: UINavigationController = {
    let navigationController = UINavigationController()
    navigationController.navigationBar.shadowImage = UIImage()
    navigationController.navigationBar.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 18, weight: .heavy)]
    return navigationController
  }()

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? BitmarkStep else { return .none }

    switch step {
    case .listOfTransactions:
      return navigateToTransactionsScreen()
    case .viewTransactionDetails(let transactionR):
      return navigateToTransactionDetails(transactionR: transactionR)
    default:
      return .none
    }
  }

  fileprivate func navigateToTransactionsScreen() -> FlowContributors {
    let viewController = TransactionsViewController()
    self.rootViewController.pushViewController(viewController, animated: true)

    return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewController))
  }

  fileprivate func navigateToTransactionDetails(transactionR: TransactionR) -> FlowContributors {
    let txDetailVC = TransactionDetailViewController()
    txDetailVC.hidesBottomBarWhenPushed = true
    txDetailVC.transactionR = transactionR
    rootViewController.pushViewController(txDetailVC)
    return .none
  }
}

class TransactionsStepper: Stepper {
  var steps = PublishRelay<Step>()

  var initialStep: Step {
    return BitmarkStep.listOfTransactions
  }
}
