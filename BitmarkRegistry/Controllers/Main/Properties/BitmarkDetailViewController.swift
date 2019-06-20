//
//  BitmarkDetailViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/17/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK

class BitmarkDetailViewController: UIViewController {

  // MARK: - Properties
  var bitmark: Bitmark!
  lazy var asset: Asset = {
    return Global.findAsset(with: bitmark.asset_id)!
  }()
  // *** Basic Properties ***
  var assetNameLabel: UILabel!
  var issueDateLabel: UILabel!
  var issuerLabel: UILabel!
  // *** Metadata Properties ***
  var metadataTableView: SelfSizedTableView!
  var metadataObjects = [(label: String, description: String)]()
  var metadataList: [String: String]! {
    didSet {
      metadataObjects.removeAll()
      for (key, value) in metadataList {
        metadataObjects.append((label: key, description: value))
      }
    }
  }
  // *** Transaction Properties ***
  var transactionTableView: UITableView!
  var transactionIndicator: UIActivityIndicatorView!
  var transactions = [Transaction]()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = asset.name.uppercased()
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
    setupEvents()

    loadData()
  }

  // MARK: - Data Handlers
  private func loadData() {
    assetNameLabel.text = asset.name
    assetNameLabel.lineHeightMultiple(1.2)
    issueDateLabel.text = bitmark.created_at?.string(withFormat: Constant.systemFullFormatDate)
    issuerLabel.text = bitmark.issuer.middleShorten()

    metadataList = asset.metadata
    metadataTableView.reloadData {
      if self.metadataObjects.isEmpty {
        self.metadataTableView.removeFromSuperview()
      } else {
        self.metadataTableView.invalidateIntrinsicContentSize()
      }
    }

    loadTransactions()
  }

  fileprivate func loadTransactions() {
    transactionIndicator.startAnimating()
    TransactionService.listAllTransactions(of: bitmark.id) { [weak self] (transactions, error) in
      guard let self = self else { return }
      DispatchQueue.main.async { self.transactionIndicator.stopAnimating() }
      guard error == nil else {
        self.showErrorAlert(message: error!.localizedDescription)
        return
      }

      self.transactions = transactions!
      DispatchQueue.main.async { self.transactionTableView.reloadData() }
    }
  }
}

// MARK: - UITableViewDataSource
extension BitmarkDetailViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tableView == metadataTableView
                      ? metadataObjects.count
                      : transactions.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if tableView == metadataTableView {
      let cell = tableView.dequeueReusableCell(withClass: MetadataDetailCell.self)
      let metadata = metadataObjects[indexPath.row]
      cell.setData(metadata)
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(withClass: TransactionCell.self)
      let transaction = transactions[indexPath.row]
      // TODO: Set Date() for now cause transaction data hasn't had timestamp yet
      cell.setData(timestamp: Date(), ownerNumber: transaction.owner)
      return cell
    }
  }
}

// MARK: - UITableViewDelegate
// Currently, only delegate for transactionTableView
extension BitmarkDetailViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 20.0
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return provenanceTableViewHeader(tableView)
  }
}

// MARK: - Setup Views/ Events
extension BitmarkDetailViewController {
  fileprivate func setupEvents() {
    metadataTableView.register(cellWithClass: MetadataDetailCell.self)
    metadataTableView.dataSource = self

    transactionTableView.register(cellWithClass: TransactionCell.self)
    transactionTableView.dataSource = self
    transactionTableView.delegate = self
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let assetInfoView = setupAssetInfoView()

    metadataTableView = SelfSizedTableView()
    metadataTableView.separatorStyle = .none
    metadataTableView.alwaysBounceVertical = false
    metadataTableView.allowsSelection = false

    let provenanceView = setupProvenanceView()

    // *** Setup UI in view ***
    let stackView = UIStackView(
      arrangedSubviews: [assetInfoView, metadataTableView, provenanceView],
      axis: .vertical,
      spacing: 30
    )

    view.addSubview(stackView)

    stackView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20))
    }
  }

  fileprivate func setupAssetInfoView() -> UIView {
    assetNameLabel = UILabel()
    assetNameLabel.font = UIFont(name: "Avenir-Black", size: 18)
    assetNameLabel.numberOfLines = 0

    let prefixIssueDateLabel = CommonUI.infoLabel(text: "ISSUED ON")
    prefixIssueDateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    issueDateLabel = CommonUI.infoLabel()

    let issueDateStackView = UIStackView(arrangedSubviews: [prefixIssueDateLabel, issueDateLabel], axis: .horizontal, spacing: 5)

    let prefixIssuerLabel = CommonUI.infoLabel(text: "BY")
    prefixIssuerLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    issuerLabel = CommonUI.infoLabel()

    let issuerStackView = UIStackView(
      arrangedSubviews: [prefixIssuerLabel, issuerLabel],
      axis: .horizontal, spacing: 5
    )

    let assetInfoView = UIView()
    assetInfoView.addSubview(assetNameLabel)
    assetInfoView.addSubview(issueDateStackView)
    assetInfoView.addSubview(issuerStackView)

    assetNameLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    issueDateStackView.snp.makeConstraints { (make) in
      make.top.equalTo(assetNameLabel.snp.bottom).offset(10)
      make.leading.trailing.equalToSuperview()
    }

    issuerStackView.snp.makeConstraints { (make) in
      make.top.equalTo(issueDateStackView.snp.bottom).offset(5)
      make.leading.trailing.bottom.equalToSuperview()
    }

    return assetInfoView
  }

  fileprivate func setupProvenanceView() -> UIView {
    let provenanceTitle = CommonUI.inputFieldTitleLabel(text: "PROVENANCE")

    transactionTableView = UITableView()
    transactionTableView.separatorStyle = .none

    transactionIndicator = UIActivityIndicatorView()
    transactionIndicator.style = .whiteLarge
    transactionIndicator.color = .gray

    let provenanceView = UIView()
    provenanceView.addSubview(provenanceTitle)
    provenanceView.addSubview(transactionTableView)
    provenanceView.addSubview(transactionIndicator)

    provenanceTitle.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    transactionTableView.snp.makeConstraints { (make) in
      make.top.equalTo(provenanceTitle.snp.bottom).offset(15)
      make.leading.trailing.bottom.equalToSuperview()
    }

    transactionIndicator.snp.makeConstraints { (make) in
      make.centerX.equalToSuperview()
      make.top.equalTo(transactionTableView).offset(50)
    }

    return provenanceView
  }

  // layout header of provenance - transactions table view
  fileprivate func provenanceTableViewHeader(_ tableView: UITableView) -> UIView {
    let timestampLabel = CommonUI.infoLabel(text: "TIMESTAMP")
    let ownerLabel = CommonUI.infoLabel(text: "OWNER")

    let stackView = UIStackView(
      arrangedSubviews: [timestampLabel, ownerLabel],
      axis: .horizontal,
      distribution: .fillProportionally
    )

    timestampLabel.snp.makeConstraints { (make) in
      make.width.equalTo(ownerLabel).multipliedBy(1.3)
    }

    let view = UIView()
    view.backgroundColor = .wildSand
    view.addSubview(stackView)

    stackView.snp.makeConstraints { (make) in
      make.edges.centerY.equalToSuperview()
    }

    return view
  }
}
