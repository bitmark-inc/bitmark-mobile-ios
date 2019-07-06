//
//  TransactionsViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/24/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK

protocol TransactionEventDelegate: class {
  func receiveNewTxs(_ newTxs: [Transaction])
  func syncUpdatedTxs()
}

class TransactionsViewController: UIViewController {

  // MARK: - Properties
  var emptyView: UIView!
  var activityIndicator: UIActivityIndicatorView!
  var txsTableView: UITableView!
  var refreshControl: UIRefreshControl!

  var transactions = [Transaction]()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "TRANSACTIONS"
    setupViews()
    setupEvents()

    loadData()
  }

  // MARK: - Data Handlers
  private func loadData() {
    activityIndicator.startAnimating()
    do {
      try TransactionStorage.shared().firstLoad { [weak self] (transactions, error) in
        guard let self = self else { return }
        self.activityIndicator.stopAnimating()

        if let error = error {
          self.showErrorAlert(message: Constant.Error.syncTransaction)
          ErrorReporting.report(error: error)
        }

        guard let transactions = transactions else { return }
        self.transactions = transactions

        if self.transactions.isEmpty {
          self.emptyView.isHidden = false
        } else {
          self.emptyView.isHidden = true
          self.txsTableView.reloadData()
        }
      }
    } catch let e {
      showErrorAlert(message: "Error happened while loading data.")
      ErrorReporting.report(error: e)
    }
  }
}

extension TransactionsViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return transactions.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withClass: TransactionListCell.self, for: indexPath)
    let transaction = transactions[indexPath.row]
    cell.loadWith(transaction)
    return cell
  }
}

extension TransactionsViewController: TransactionEventDelegate {
  func receiveNewTxs(_ newTxs: [Transaction]) {
    for newTx in newTxs {
      txsTableView.beginUpdates()
      // Remove obsolete bitmark which is displaying in table
      if let index = transactions.firstIndexWithId(newTx.id) {
        transactions.remove(at: index)
        txsTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .none)
      }

      // Add new transaction
      transactions.prepend(newTx)
      txsTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)

      emptyView.isHidden = !transactions.isEmpty
      txsTableView.endUpdates()
    }
  }

  @objc func syncUpdatedTxs() {
    TransactionStorage.shared().asyncUpdateInSerialQueue(notifyNew: true, doRepeat: false) { [weak self] (_) in
      DispatchQueue.main.async {
        self?.refreshControl.endRefreshing()
      }
    }
  }
}

// MARK: - Setup Views/Events
extension TransactionsViewController {
  fileprivate func setupEvents() {
    TransactionStorage.shared().delegate = self

    txsTableView.register(cellWithClass: TransactionListCell.self)
    txsTableView.dataSource = self
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(syncUpdatedTxs), for: .valueChanged)
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
    }

    activityIndicator.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
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
    view.isHidden = true
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
