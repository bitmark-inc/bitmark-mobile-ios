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

  var assetNameLabel: UILabel!
  var issueDateLabel: UILabel!
  var issuerLabel: UILabel!

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

  var transactionTableView: UITableView!
  var transactionIndicator: UIActivityIndicatorView!
  var transactions = [Transaction]()

  var actionMenuView: UIView!
  var menuBarButton: UIBarButtonItem!
  var copyIdButton: UIButton!
  var copiedToClipboardNotifier: UILabel!
  var downloadButton: UIButton!
  var transferButton: UIButton!
  var deleteButton: UIButton!


  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = asset.name.uppercased()
    menuBarButton = UIBarButtonItem(image: UIImage(named: "More Actions-close"), style: .plain, target: self, action: #selector(tapToOpenActionMenu))
    navigationItem.rightBarButtonItem = menuBarButton
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
    setupEvents()

    loadData()

  }

  // MARK: - Data Handlers
  private func loadData() {
    assetNameLabel.text = asset.name
    _ = assetNameLabel.lineHeightMultiple(1.2)
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
      guard error == nil else {
        self.showErrorAlert(message: error!.localizedDescription)
        return
      }

      self.transactions = transactions!
      DispatchQueue.main.async {
        self.transactionIndicator.stopAnimating()
        self.transactionTableView.reloadData()
      }
    }
  }

  // MARK: - Handlers
  @objc func tapToOpenActionMenu(_ sender: UIBarButtonItem) {
    actionMenuView.isHidden = !actionMenuView.isHidden
    sender.image = UIImage(named: actionMenuView.isHidden ? "More Actions-close" : "More Actions-open")
  }

  @objc func tapToCopyId(_ sender: UIButton) {
    UIPasteboard.general.string = bitmark.id
    copiedToClipboardNotifier.showIn(period: 1.2)
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
      cell.setData(timestamp: Date(), owner: transaction.owner)
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
    metadataTableView.dataSource = self
    metadataTableView.register(cellWithClass: MetadataDetailCell.self)

    transactionTableView.dataSource = self
    transactionTableView.delegate = self
    transactionTableView.register(cellWithClass: TransactionCell.self)

    copyIdButton.addTarget(self, action: #selector(tapToCopyId), for: .touchUpInside)
    transferButton.addAction(for: .touchUpInside) {
      self.performMoveToTransferBitmark()
    }
  }

  fileprivate func performMoveToTransferBitmark() {
    tapToOpenActionMenu(menuBarButton)
    let transferBitmarkVC = TransferBitmarkViewController()
    transferBitmarkVC.assetName = asset.name
    transferBitmarkVC.bitmarkId = bitmark.id
    navigationController?.pushViewController(transferBitmarkVC)
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

    actionMenuView = setupActionMenuView()
    actionMenuView.backgroundColor = .wildSand
    actionMenuView.addShadow(ofColor: .gray)
    actionMenuView.isHidden = true

    view.addSubview(stackView)
    view.addSubview(actionMenuView)

    stackView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20))
    }

    actionMenuView.snp.makeConstraints { (make) in
      make.width.equalTo(180)
      make.top.trailing.equalTo(view.safeAreaLayoutGuide)
    }
  }

  fileprivate func setupActionMenuView() -> UIView {
    copyIdButton = CommonUI.actionMenuButton(title: "COPY ID")

    copiedToClipboardNotifier = UILabel(text: "Copied to clipboard!")
    copiedToClipboardNotifier.font = UIFont(name: "Avenir", size: 8)?.italic
    copiedToClipboardNotifier.textColor = .mainBlueColor
    copiedToClipboardNotifier.textAlignment = .right
    copiedToClipboardNotifier.isHidden = true

    let copyIdView = UIView()
    copyIdView.addSubview(copyIdButton)
    copyIdView.addSubview(copiedToClipboardNotifier)

    copyIdButton.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    copiedToClipboardNotifier.snp.makeConstraints { (make) in
      make.top.equalTo(copyIdButton.snp.bottom).offset(-5)
      make.leading.trailing.bottom.equalToSuperview()
    }

    downloadButton = CommonUI.actionMenuButton(title: "DOWNLOAD")
    transferButton = CommonUI.actionMenuButton(title: "TRANSFER")
    deleteButton = CommonUI.actionMenuButton(title: "DELETE")

    let stackview = UIStackView(
      arrangedSubviews: [copyIdView, downloadButton, transferButton, deleteButton],
      axis: .vertical,
      spacing: 15,
      alignment: .trailing,
      distribution: .fill
    )

    let view = UIView()
    view.addSubview(stackview)
    stackview.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
          .inset(UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20))
    }
    return view
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

    let issuerStackView = UIStackView(arrangedSubviews: [prefixIssuerLabel, issuerLabel], axis: .horizontal, spacing: 5)

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
