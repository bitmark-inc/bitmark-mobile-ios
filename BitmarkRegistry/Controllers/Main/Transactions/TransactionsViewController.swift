//
//  TransactionsViewController.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 6/24/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import BitmarkSDK
import RealmSwift
import RxFlow
import RxCocoa

class TransactionsViewController: UIViewController, Stepper {
  var steps = PublishRelay<Step>()

  // MARK: - Properties
  var emptyView: UIView!
  var activityIndicator: UIActivityIndicatorView!
  var txsTableView: UITableView!
  var refreshControl: UIRefreshControl!

  var transactionRs: Results<TransactionR>!
  fileprivate var realmToken: NotificationToken?

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.title = "Transactions".localized().localizedUppercase
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
    setupEvents()

    loadData()
    setupBitmarkEventSubscription()
  }

  // MARK: - Data Handlers
  private func loadData() {
    activityIndicator.startAnimating()
    do {
      try TransactionStorage.shared().firstLoad { [weak self] (error) in
        guard let self = self else { return }
        self.activityIndicator.stopAnimating()

        if let error = error {
          self.showErrorAlert(message: "syncTransaction".localized(tableName: "Error"))
          ErrorReporting.report(error: error)
          return
        }

        do {
          self.transactionRs = try TransactionStorage.shared().getData()
        } catch {
          self.showErrorAlert(message: "loadTransaction".localized(tableName: "Error"))
          ErrorReporting.report(error: error)
          return
        }

        self.setupRealmObserverForLoadingTransactions()
      }
    } catch {
      showErrorAlert(message: "loadTransaction".localized(tableName: "Error"))
      ErrorReporting.report(error: error)
    }
  }

  fileprivate func setupRealmObserverForLoadingTransactions() {
    self.realmToken = self.transactionRs.observe({ [weak self] (changes) in
      guard let self = self else { return }
      self.txsTableView.apply(changes: changes)
      self.emptyView.isHidden = !self.transactionRs.isEmpty
    })
  }
}

extension TransactionsViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return transactionRs?.count ?? 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withClass: TransactionListCell.self, for: indexPath)
    let transactionR = transactionRs[indexPath.row]
    cell.loadWith(transactionR)
    if transactionR.status == TransactionStatus.pending.rawValue || transactionR.txType == TransactionType.claimRequest.rawValue {
      cell.isUserInteractionEnabled = false
    }
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let transactionR = transactionRs[indexPath.row]
    steps.accept(BitmarkStep.viewTransactionDetails(transactionR: transactionR))
  }
}

// MARK: EventDelegate
extension TransactionsViewController: EventDelegate {
  @objc func syncUpdatedRecords() {
    TransactionStorage.shared().asyncUpdateInSerialQueue { [weak self] (_) in
      DispatchQueue.main.async {
        self?.refreshControl.endRefreshing()
      }
    }
  }
}

// MARK: - Setup Views/Events
extension TransactionsViewController {
  fileprivate func setupEvents() {
    txsTableView.register(cellWithClass: TransactionListCell.self)
    txsTableView.dataSource = self
    txsTableView.delegate = self
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(syncUpdatedRecords), for: .valueChanged)
    refreshControl.tintColor = UIColor.gray

    txsTableView = UITableView()
    txsTableView.tableFooterView = UIView()
    txsTableView.addSubview(refreshControl)

    emptyView = setupEmptyView()
    activityIndicator = CommonUI.appActivityIndicator()

    let mainView = UIView()
    mainView.addSubview(txsTableView)
    mainView.addSubview(emptyView)
    mainView.addSubview(activityIndicator)

    txsTableView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }

    emptyView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
          .inset(UIEdgeInsets(top: 15, left: 20, bottom: 0, right: 20))
    }

    activityIndicator.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
    }

    // *** Setup UI in view ***
    view.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 10, left: 0, bottom: 25, right: 0))
    }
  }

  fileprivate func setupEmptyView() -> UIView {
    let titleLabel = CommonUI.pageTitleLabel(text: "transactions_noTxHistoryTitle".localized(tableName: "Phrase").localizedUppercase)
    titleLabel.textColor = .mainBlueColor

    let descriptionLabel = CommonUI.descriptionLabel(text: "transactions_noTxHistoryMessage".localized(tableName: "Phrase"))

    let view = UIView()
    view.isHidden = true
    view.addSubview(titleLabel)
    view.addSubview(descriptionLabel)

    titleLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    descriptionLabel.snp.makeConstraints { (make) in
      make.top.equalTo(titleLabel.snp.bottom).offset(27)
      make.leading.trailing.equalToSuperview()
    }

    return view
  }
}
