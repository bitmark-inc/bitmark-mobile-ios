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
import RxSwift
import RxFlow
import RxCocoa

class BitmarkDetailViewController: UIViewController, Stepper {
  var steps = PublishRelay<Step>()

  // MARK: - Properties
  var bitmarkR: BitmarkR!
  var assetR: AssetR!
  // *** Basic Properties ***
  var thumbnailImageView: UIImageView!
  var assetNameLabel: UILabel!
  var issueDateLabel: UILabel!
  var pendingIssueDateLabel: UILabel!
  var prefixIssueDateLabel: UILabel!
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
  var tapRecognizer: UITapGestureRecognizer!
  lazy var assetFileService = {
    return AssetFileService(owner: Global.currentAccount!, assetId: assetR.id)
  }()
  var networkReachabilityManager = NetworkReachabilityManager()
  var assetNotificationToken: NotificationToken?
  var bitmarkNotificationToken: NotificationToken?
  var txNotificationToken: NotificationToken?
  let disposeBag = DisposeBag()

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
    markRead()
  }

  deinit {
    assetNotificationToken?.invalidate()
    bitmarkNotificationToken?.invalidate()
    txNotificationToken?.invalidate()
  }

  // MARK: - Data Handlers
  fileprivate func markRead() {
    do {
      try BitmarkStorage.shared().markRead(for: bitmarkR)
    } catch {
      ErrorReporting.report(error: error)
    }
  }

  private func loadData() {
    if let assetType = assetR.assetType {
      thumbnailImageView.image = AssetType(rawValue: assetType)?.thumbnailImage()
    }
    assetNameLabel.text = assetR.name
    assetNameLabel.lineHeightMultiple(1.2)

    metadataTableView.reloadData { [weak self] in
      guard let self = self else { return }
      if self.assetR.metadata.isEmpty {
        self.metadataTableView.removeFromSuperview()
      } else {
        self.metadataTableView.invalidateIntrinsicContentSize()
      }
    }

    setupStyleBitmark()
    enableActionButtons()
    setupRealmObserverForLoadingBitmarkInfo()

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
        self.setupRealmObserverForLoadingTxs()
      }
    }
  }

  fileprivate func setupRealmObserverForLoadingTxs() {
    self.txNotificationToken = self.transactionRs.observe({ [unowned self] (changes) in
      self.transactionTableView.apply(changes: changes)
    })
  }

  fileprivate func setupRealmObserverForLoadingBitmarkInfo() {
    if bitmarkR.createdAt == nil || bitmarkR.confirmedAt == nil {
      bitmarkNotificationToken = bitmarkR.observe({ [unowned self] (changes) in
        switch changes {
        case .change(let properties):
          for property in properties {
            guard property.name == "confirmedAt" else { continue }
            self.setupStyleBitmark()
            BitmarkStorage.shared().loadTxRs(for: self.bitmarkR, forceSync: true, completion: {_, _ in })
            self.enableActionButtons()
          }
        case .error(let error):
          ErrorReporting.report(error: error)
        case .deleted:
          ErrorReporting.report(message: "the bitmark object is deleted.")
        }
      })
    }

    assetNotificationToken = assetR.observe { [unowned self] (changes) in
      switch changes {
      case .change(let properties):
        for property in properties {
          if property.name == "assetType", let assetType = property.newValue as? String {
            self.thumbnailImageView.image = AssetType(rawValue: assetType)?.thumbnailImage()
          }
        }
      case .error(let error):
        ErrorReporting.report(error: error)
      case .deleted:
        ErrorReporting.report(message: "the asset object is deleted.")
      }
    }
  }

  // MARK: - Handlers
  @objc func tapToToggleActionMenu(_ sender: UIBarButtonItem) {
    actionMenuView.isHidden = !actionMenuView.isHidden
    sender.image = UIImage(named: actionMenuView.isHidden ? "More Actions-close" : "More Actions-open")
    tapRecognizer.cancelsTouchesInView = !actionMenuView.isHidden
  }

  @objc func closeActionMenu(_ sender: UIGestureRecognizer) {
    guard !actionMenuView.isHidden else { return }
    actionMenuView.isHidden = true
    menuBarButton.image = UIImage(named: "More Actions-close")
    tapRecognizer.cancelsTouchesInView = false
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

    showIndicatorAlert(message: "preparingToExport".localized(tableName: "Message")) { (selfAlert) in
      self.assetFileService.getDownloadedFileURL(assetFilename: self.assetR.filename)
        .subscribe(
          onNext: { (downloadedFileURL) in
            selfAlert.dismiss(animated: true, completion: { [weak self] in
              guard let self = self else { return }
              let shareVC = UIActivityViewController(activityItems: [downloadedFileURL], applicationActivities: [])
              self.present(shareVC, animated: true)
              self.assetR.updateAssetFileInfo(downloadedFileURL.path)
            })
          },
          onError: { _ in
            selfAlert.dismiss(animated: true, completion: { [weak self] in
              self?.showErrorAlert(message: "noReadyToDownload".localized(tableName: "Error"))
            })
          })
        .disposed(by: self.disposeBag)
    }
  }

  @objc func tapToDelete(_ sender: UIButton) {
    let alertController = UIAlertController(
      title: "deleteBitmark_titleModal".localized(tableName: "Phrase"),
      message: nil, preferredStyle: .actionSheet
    )
    alertController.addAction(title: "Delete".localized(), style: .destructive, handler: deleteBitmark)
    alertController.addAction(title: "Cancel".localized(), style: .cancel)
    present(alertController, animated: true, completion: nil)
  }

  // delete bitmark means transfer bitmark to zero address
  fileprivate func deleteBitmark(_ sender: UIAlertAction) {
    requireAuthenticationForAction(disposeBag) { [weak self] in
      self?._deleteBitmark()
    }
  }

  fileprivate func _deleteBitmark() {
    guard  let networkReachabilityManager = networkReachabilityManager, networkReachabilityManager.isReachable else {
      Global.showNoInternetBanner()
      return
    }

    let zeroAccountNumber = Credential.valueForKey(keyName: Constant.InfoKey.zeroAddress)
    showIndicatorAlert(message: "deletingBitmark".localized(tableName: "Message")) { (selfAlert) in
      do {
        _ = try BitmarkService.directTransfer(
          account: Global.currentAccount!,
          bitmarkId: self.bitmarkR.id,
          to: zeroAccountNumber
        )

        selfAlert.dismiss(animated: true, completion: {
          Global.syncNewDataInStorage()

          self.showQuickMessageAlert(message: "successDelete".localized(tableName: "Message")) { [weak self] in
            self?.steps.accept(BitmarkStep.deleteBitmarkIsComplete)
          }
        })
      } catch {
        selfAlert.dismiss(animated: true, completion: {
          self.showErrorAlert(message: "deleteBitmark_unsuccessfully".localized(tableName: "Error"))
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
      let cell = tableView.dequeueReusableCell(withClass: MetadataDetailCell.self, for: indexPath)
      let metadata = assetR.metadata[indexPath.row]
      cell.setData(metadata)
      cell.isBitmarkConfirmed = bitmarkR.createdAt != nil
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(withClass: TransactionCell.self, for: indexPath)
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

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let cell = tableView.cellForRow(at: indexPath) as? TransactionCell,
          cell.isConfirmed else { return }
    let txR = transactionRs[indexPath.row]
    steps.accept(BitmarkStep.viewRegistryAccountDetails(accountNumber: txR.owner))
  }
}

// MARK: - Support Functions
extension BitmarkDetailViewController {
  fileprivate func setupStyleBitmark() {
    let isPending = bitmarkR.confirmedAt == nil
    let styledColor: UIColor = isPending ? .dustyGray : .black

    assetNameLabel.textColor = styledColor

    pendingIssueDateLabel.text = statusInWord(status: bitmarkR.status)
    pendingIssueDateLabel.isHidden = !isPending

    prefixIssueDateLabel.isHidden = isPending
    issueDateLabel.text = isPending ? "" : CustomUserDisplay.date(bitmarkR.createdAt)

    if let metadataCells = self.metadataTableView.visibleCells as? [MetadataDetailCell] {
      metadataCells.forEach({ $0.isBitmarkConfirmed = !isPending })
    }
  }

  // enable status for menu buttons base on the bitmark's status
  fileprivate func enableActionButtons() {
    let isBitmarkSettled = BitmarkStatus(rawValue: bitmarkR.status) == .settled
    downloadButton.isEnabled = isBitmarkSettled
    transferButton.isEnabled = isBitmarkSettled
    deleteButton.isEnabled = isBitmarkSettled
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

    transferButton.addAction(for: .touchUpInside) { [weak self] in
      self?.performMoveToTransferBitmark()
    }
  }

  fileprivate func performMoveToTransferBitmark() {
    tapToToggleActionMenu(menuBarButton)
    steps.accept(BitmarkStep.viewTransferBitmark(bitmarkId: bitmarkR.id, assetR: assetR))
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let assetInfoView = setupAssetInfoView()

    metadataTableView = SelfSizedTableView()
    metadataTableView.snp.makeConstraints { (make) in
      make.height.lessThanOrEqualTo(120)
    }
    metadataTableView.separatorStyle = .none
    metadataTableView.alwaysBounceVertical = false
    metadataTableView.allowsSelection = false

    let provenanceView = setupProvenanceView()

    // *** Setup UI in view ***
    let stackView = UIStackView(
      arrangedSubviews: [assetInfoView, metadataTableView, provenanceView],
      axis: .vertical,
      spacing: 25
    )

    actionMenuView = setupActionMenuView()
    actionMenuView.backgroundColor = .wildSand
    actionMenuView.addShadow(ofColor: .gray)
    actionMenuView.isHidden = true

    tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeActionMenu))
    tapRecognizer.cancelsTouchesInView = false

    activityIndicator = CommonUI.appActivityIndicator()

    view.addSubview(stackView)
    view.addGestureRecognizer(tapRecognizer)
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
    copyIdButton = CommonUI.actionMenuButton(title: "CopyBitmarkId".localized().localizedUppercase)

    copiedToClipboardNotifier = UILabel(text: "CopiedToClipboard".localized())
    copiedToClipboardNotifier.font = UIFont(name: "Avenir-BlackOblique", size: 8)
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

    downloadButton = CommonUI.actionMenuButton(title: "Download".localized().localizedUppercase)
    transferButton = CommonUI.actionMenuButton(title: "Transfer".localized().localizedUppercase)
    deleteButton = CommonUI.actionMenuButton(title: "Delete".localized().localizedUppercase)

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

    return view
  }

  fileprivate func setupAssetInfoView() -> UIView {
    thumbnailImageView = UIImageView()
    thumbnailImageView.contentMode = .scaleAspectFit

    assetNameLabel = UILabel()
    assetNameLabel.font = UIFont(name: "Avenir-Black", size: 18)
    assetNameLabel.numberOfLines = 0

    prefixIssueDateLabel = CommonUI.infoLabel(text: "bitmarkDetail_issuedOn".localized(tableName: "Phrase"))
    prefixIssueDateLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    pendingIssueDateLabel = CommonUI.infoLabel()
    pendingIssueDateLabel.textColor = .dustyGray

    issueDateLabel = CommonUI.infoLabel()

    let issueDateStackView = UIStackView(arrangedSubviews: [pendingIssueDateLabel, prefixIssueDateLabel, issueDateLabel], axis: .horizontal, spacing: 5)

    let assetInfoView = UIView()
    assetInfoView.addSubview(thumbnailImageView)
    assetInfoView.addSubview(assetNameLabel)
    assetInfoView.addSubview(issueDateStackView)

    thumbnailImageView.snp.makeConstraints { (make) in
      make.top.leading.equalToSuperview()
      make.width.equalTo(80)
      make.height.equalTo(63)
    }

    assetNameLabel.snp.makeConstraints { (make) in
      make.top.equalTo(thumbnailImageView.snp.bottom).offset(35)
      make.leading.trailing.equalToSuperview()
    }

    issueDateStackView.snp.makeConstraints { (make) in
      make.top.equalTo(assetNameLabel.snp.bottom).offset(10)
      make.leading.trailing.bottom.equalToSuperview()
    }

    return assetInfoView
  }

  fileprivate func setupProvenanceView() -> UIView {
    let provenanceTitle = UILabel(text: "Provenance".localized().localizedUppercase)
    provenanceTitle.font = UIFont(name: "Avenir-Black", size: 14)

    transactionTableView = UITableView()
    transactionTableView.separatorStyle = .none
    transactionTableView.alwaysBounceVertical = false

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
    let timestampLabel = CommonUI.infoLabel(text: "Timestamp".localized().localizedUppercase)
    let ownerLabel = CommonUI.infoLabel(text: "Owner".localized().localizedUppercase)

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

// MARK: - Support Functions
extension BitmarkDetailViewController {
  fileprivate func statusInWord(status: String) -> String {
    switch BitmarkStatus(rawValue: status)! {
    case .issuing:
      return "Registering".localized().localizedUppercase
    case .transferring:
      return "Incoming".localized().localizedUppercase
    default:
      return ""
    }
  }
}
