//
//  BitmarkDetailViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/17/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK
import Alamofire
import RealmSwift

class BitmarkDetailViewController: UIViewController {

  // MARK: - Properties
  var bitmarkR: BitmarkR!
  var assetR: AssetR!
  // *** Basic Properties ***
  var assetNameLabel: UILabel!
  var issueDateLabel: UILabel!
  var issuerLabel: UILabel!
  // *** Metadata Properties ***
  var metadataTableView: SelfSizedTableView!
  // *** Transaction Properties ***
  var transactionTableView: UITableView!
  var transactionIndicator: UIActivityIndicatorView!
  var transactionRs: Results<TransactionR>!
  // *** Action Menu ***
  var actionMenuView: UIView!
  var menuBarButton: UIBarButtonItem!
  var copyIdButton: UIButton!
  var copiedToClipboardNotifier: UILabel!
  var downloadButton: UIButton!
  var transferButton: UIButton!
  var deleteButton: UIButton!
  var activityIndicator: UIActivityIndicatorView!
  lazy var assetFileService = {
    return AssetFileService(owner: Global.currentAccount!, assetId: assetR.id)
  }()
  var networkReachabilityManager = NetworkReachabilityManager()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = assetR.name.uppercased()
    navigationItem.backBarButtonItem = UIBarButtonItem()
    menuBarButton = UIBarButtonItem(image: UIImage(named: "More Actions-close"), style: .plain, target: self, action: #selector(tapToToggleActionMenu))
    navigationItem.rightBarButtonItem = menuBarButton
    setupViews()
    setupEvents()

    loadData()
  }

  // MARK: - Data Handlers
  private func loadData() {
    assetNameLabel.text = assetR.name
    assetNameLabel.lineHeightMultiple(1.2)
    issueDateLabel.text = CustomUserDisplay.datetime(bitmarkR.createdAt)
    issuerLabel.text = CustomUserDisplay.accountNumber(bitmarkR.issuer)

    metadataTableView.reloadData { [weak self] in
      guard let self = self else { return }
      if self.assetR.metadata.isEmpty {
        self.metadataTableView.removeFromSuperview()
      } else {
        self.metadataTableView.invalidateIntrinsicContentSize()
      }
    }

    loadTransactions()
  }

  fileprivate func loadTransactions() {
    transactionIndicator.startAnimating()
    BitmarkStorage.shared().loadTxRs(for: bitmarkR) { [weak self] (resultsTxRs, error) in
      guard let self = self else { return }
      DispatchQueue.main.async {
        self.transactionIndicator.stopAnimating()
        if let error = error {
          self.showErrorAlert(message: error.localizedDescription)
          ErrorReporting.report(error: error)
          return
        }

        self.transactionRs = resultsTxRs
        self.transactionTableView.reloadData()
      }
    }
  }

  // MARK: - Handlers
  @objc func tapToToggleActionMenu(_ sender: UIBarButtonItem) {
    actionMenuView.isHidden = !actionMenuView.isHidden
    sender.image = UIImage(named: actionMenuView.isHidden ? "More Actions-close" : "More Actions-open")
  }

  @objc func closeActionMenu(_ sender: UIGestureRecognizer) {
    guard !actionMenuView.isHidden else { return }
    actionMenuView.isHidden = true
    menuBarButton.image = UIImage(named: "More Actions-close")
  }

  @objc func tapToCopyId(_ sender: UIButton) {
    UIPasteboard.general.string = bitmarkR.id
    copiedToClipboardNotifier.showIn(period: 1.2)
  }

  @objc func tapToDownload(_ sender: UIButton) {
    guard let networkReachabilityManager = networkReachabilityManager, networkReachabilityManager.isReachable else {
      Global.showNoInternetBanner()
      return
    }

    showIndicatorAlert(message: Constant.Message.preparingToExport) { (selfAlert) in
      self.assetFileService.getDownloadedFileURL { [weak self] (downloadedFileURL, error) in
        guard let self = self else { return }

        selfAlert.dismiss(animated: true, completion: {
          if let error = error {
            self.showErrorAlert(message: Constant.Error.downloadAsset)
            ErrorReporting.report(error: error)
            return
          }

          guard let downloadedFileURL = downloadedFileURL else { return }
          let shareVC = UIActivityViewController(activityItems: [downloadedFileURL], applicationActivities: [])
          self.present(shareVC, animated: true)
        })
      }
    }
  }

  @objc func tapToDelete(_ sender: UIButton) {
    let alertController = UIAlertController(title: "This bitmark will be deleted.", message: nil, preferredStyle: .actionSheet)
    alertController.addAction(title: "Delete", style: .destructive, handler: deleteBitmark)
    alertController.addAction(title: "Cancel", style: .cancel)
    present(alertController, animated: true, completion: nil)
  }

  // delete bitmark means transfer bitmark to zero address
  fileprivate func deleteBitmark(_ sender: UIAlertAction) {
    guard  let networkReachabilityManager = networkReachabilityManager, networkReachabilityManager.isReachable else {
      Global.showNoInternetBanner()
      return
    }

    let zeroAccountNumber = Credential.valueForKey(keyName: Constant.InfoKey.zeroAddress)
    showIndicatorAlert(message: Constant.Message.deletingBitmark) { (selfAlert) in
      do {
        _ = try BitmarkService.directTransfer(
          account: Global.currentAccount!,
          bitmarkId: self.bitmarkR.id,
          to: zeroAccountNumber
        )

        selfAlert.dismiss(animated: true, completion: {
          Global.syncNewDataInStorage()

          self.showSuccessAlert(message: Constant.Success.delete, handler: {
            self.navigationController?.popToRootViewController(animated: true)
          })
        })
      } catch {
        selfAlert.dismiss(animated: true, completion: {
          self.showErrorAlert(message: error.localizedDescription)
          ErrorReporting.report(error: error)
        })
      }
    }
  }
}

// MARK: - UITableViewDataSource
extension BitmarkDetailViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tableView == metadataTableView
                      ? assetR.metadata.count
                      : (transactionRs?.count ?? 0)
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if tableView == metadataTableView {
      let cell = tableView.dequeueReusableCell(withClass: MetadataDetailCell.self)
      let metadata = assetR.metadata[indexPath.row]
      cell.setData(metadata)
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(withClass: TransactionCell.self)
      let txR = transactionRs[indexPath.row]
      cell.setData(timestamp: txR.confirmedAt, ownerNumber: txR.owner)
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

    copyIdButton.addTarget(self, action: #selector(tapToCopyId), for: .touchUpInside)
    downloadButton.addTarget(self, action: #selector(tapToDownload), for: .touchUpInside)
    deleteButton.addTarget(self, action: #selector(tapToDelete), for: .touchUpInside)

    transferButton.addAction(for: .touchUpInside) {
      self.performMoveToTransferBitmark()
    }
  }

  fileprivate func performMoveToTransferBitmark() {
    tapToToggleActionMenu(menuBarButton)
    let transferBitmarkVC = TransferBitmarkViewController()
    transferBitmarkVC.assetR = assetR
    transferBitmarkVC.bitmarkId = bitmarkR.id
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

    let recognizer = UITapGestureRecognizer(target: self, action: #selector(closeActionMenu))
    recognizer.cancelsTouchesInView = true

    activityIndicator = CommonUI.appActivityIndicator()

    view.addSubview(stackView)
    view.addGestureRecognizer(recognizer)
    view.addSubview(actionMenuView)
    view.addSubview(activityIndicator)

    stackView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20))
    }

    actionMenuView.snp.makeConstraints { (make) in
      make.width.equalTo(180)
      make.top.trailing.equalTo(view.safeAreaLayoutGuide)
    }

    activityIndicator.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
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

    stackview.arrangedSubviews.forEach { (subview) in
      subview.snp.makeConstraints { $0.width.equalToSuperview() }
    }

    let view = UIView()
    view.addSubview(stackview)
    stackview.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
        .inset(UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20))
    }

    // enable status for menu buttons base on the bitmark's status
    if BitmarkStatus(rawValue: bitmarkR.status) != .settled {
      downloadButton.isEnabled = false
      transferButton.isEnabled = false
      deleteButton.isEnabled = false
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

    transactionIndicator = CommonUI.appActivityIndicator()

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
