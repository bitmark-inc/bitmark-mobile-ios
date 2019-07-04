//
//  TransactionsViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/24/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK

class TransactionsViewController: UIViewController {

  // MARK: - Properties
  var emptyView: UIView!

  var transactions = [Transaction]()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "TRANSACTIONS"
    setupViews()

    loadData()
  }

  // MARK: - Data Handlers
  private func loadData() {
    do {
      try TransactionStorage.shared().firstLoad { [weak self] (transactions, error) in
        guard let self = self else { return }

        if let error = error {
          ErrorReporting.report(error: error)
          self.showErrorAlert(message: Constant.Error.syncTransaction)
        }

        guard let transactions = transactions else { return }
        self.transactions = transactions

        if self.transactions.isEmpty {
          self.emptyView.isHidden = false
        } else {
          self.emptyView.isHidden = true
        }
      }
    } catch let e {
      showErrorAlert(message: "Error happened while loading data.")
      ErrorReporting.report(error: e)
    }
  }
}

// MARK: - Setup Views
extension TransactionsViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    emptyView = setupEmptyView()

    let mainView = UIView()
    mainView.addSubview(emptyView)

    emptyView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }

    // *** Setup UI in view ***
    view.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20))
    }
  }

  fileprivate func setupEmptyView() -> UIView {
    let titleLabel = CommonUI.pageTitleLabel(text: "NO TRANSACTION HISTORY.")
    titleLabel.textColor = .mainBlueColor

    let descriptionLabel = CommonUI.descriptionLabel(text: "Your transaction history will be available here.")

    let view = UIView()
    view.addSubview(titleLabel)
    view.addSubview(descriptionLabel)

    titleLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    descriptionLabel.snp.makeConstraints { (make) in
      make.top.equalTo(titleLabel.snp.bottom).offset(35)
      make.leading.trailing.equalToSuperview()
    }

    return view
  }

  
}
