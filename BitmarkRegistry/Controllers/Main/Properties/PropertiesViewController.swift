//
//  PropertiesViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK

class PropertiesViewController: UIViewController {

  // MARK: - Properties
  var yoursView: UIView!
  var globalView: DesignedWebView!

  lazy var segmentControl: UISegmentedControl = {
    let segmentControl = UISegmentedControl()
    segmentControl.segmentTitles = ["YOURS", "GLOBAL"]
    segmentControl.selectedSegmentIndex = 0
    segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    return segmentControl
  }()

  //*** Yours Segment ***
  var refreshControl: UIRefreshControl!
  var yoursTableView: UITableView!
  var createFirstProperty: UIButton!
  var emptyViewInYoursTab: UIView!
  var yoursActivityIndicator: UIActivityIndicatorView!
  var bitmarks = [Bitmark]()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "PROPERTIES"
    let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(tapToAddProperty))
    navigationItem.rightBarButtonItem = addBarButton
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
    setupEvents()

    loadData()
    setupBitmarkEventSubscription()
  }

  // MARK: - Data Handlers
  private func loadData() {
    yoursActivityIndicator.startAnimating()
    do {
      try BitmarkStorage.shared().firstLoad { [weak self] (bitmarks, error) in
        guard let self = self else { return }
        self.yoursActivityIndicator.stopAnimating()

        if let error = error {
          self.showErrorAlert(message: Constant.Error.syncBitmark)
          ErrorReporting.report(error: error)
        }

        guard let bitmarks = bitmarks else { return }
        self.bitmarks = bitmarks

        if self.bitmarks.isEmpty {
          self.emptyViewInYoursTab.isHidden = false
        } else {
          self.emptyViewInYoursTab.isHidden = true
          self.yoursTableView.reloadData()
        }
      }
    } catch {
      showErrorAlert(message: "Error happened while loading data.")
      ErrorReporting.report(error: error)
    }
  }

  func setupBitmarkEventSubscription() {
    do {
      let eventSubscription = EventSubscription.shared
      try eventSubscription.connect(Global.currentAccount!)

      try eventSubscription.listenBitmarkChanged { [weak self] (_) in
        self?.syncUpdatedRecords()
      }
    } catch {
      ErrorReporting.report(error: error)
    }
  }

  // MARK: - Handlers
  @objc func tapToAddProperty() {
    navigationController?.pushViewController(
      RegisterPropertyViewController()
    )
  }

  @objc func segmentChanged(_ sender: UISegmentedControl) {
    switch sender.selectedSegmentIndex {
    case 0:
      yoursView.isHidden = false
      globalView.isHidden = true
    case 1:
      yoursView.isHidden = true
      globalView.isHidden = false
      globalView.loadWeb()
    default:
      break
    }
  }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension PropertiesViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return bitmarks.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withClass: YourPropertyCell.self)
    let bitmark = bitmarks[indexPath.row]
    let asset = Global.findAsset(with: bitmark.asset_id)
    cell.loadWith(asset, bitmark)
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let bitmark = bitmarks[indexPath.row]
    let bitmarkDetailsVC = BitmarkDetailViewController()
    bitmarkDetailsVC.hidesBottomBarWhenPushed = true
    bitmarkDetailsVC.bitmark = bitmark
    navigationController?.pushViewController(bitmarkDetailsVC)
  }
}

// MARK: BitmarkEventDelegate
extension PropertiesViewController: EventDelegate {
  typealias Record = Bitmark

  @objc func syncUpdatedRecords() {
    BitmarkStorage.shared().asyncUpdateInSerialQueue(notifyNew: true, doRepeat: false) { [weak self] (_) in
      DispatchQueue.main.async {
        self?.refreshControl.endRefreshing()
      }
    }
  }

  func receiveNewRecords(_ newRecords: [Bitmark]) {
    for newBitmark in newRecords {
      yoursTableView.beginUpdates()
      // Remove obsolete bitmark which is displaying in table
      if let index = bitmarks.firstIndexWithId(newBitmark.id) {
        bitmarks.remove(at: index)
        yoursTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .none)
      }
      // Add new bitmark; ignore if bitmark is obsolete
      if newBitmark.owner == Global.currentAccount?.getAccountNumber() {
        bitmarks.prepend(newBitmark)
        yoursTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
      }

      emptyViewInYoursTab.isHidden = !bitmarks.isEmpty
      yoursTableView.endUpdates()
    }
  }
}

// MARK: - Setup Views/Events
extension PropertiesViewController {
  fileprivate func setupEvents() {
    // *** Yours Segment ***
    BitmarkStorage.shared().delegate = self
    yoursTableView.register(cellWithClass: YourPropertyCell.self)
    yoursTableView.dataSource = self
    yoursTableView.delegate = self

    createFirstProperty.addTarget(self, action: #selector(tapToAddProperty), for: .touchUpInside)
    segmentControl.sendActions(for: .valueChanged)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    yoursView = setupYoursView()
    globalView = DesignedWebView(urlString: globalRegisterApp)

    // *** Setup UI in view ***
    view.addSubview(segmentControl)
    view.addSubview(yoursView)
    view.addSubview(globalView)

    segmentControl.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      make.height.equalTo(35)
    }

    yoursView.snp.makeConstraints { (make) in
      make.top.equalTo(segmentControl.snp.bottom)
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }

    globalView.snp.makeConstraints { (make) in
      make.top.equalTo(segmentControl.snp.bottom)
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }
  }

  fileprivate func setupYoursView() -> UIView {
    refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: #selector(syncUpdatedRecords), for: .valueChanged)
    refreshControl.tintColor = UIColor.gray

    yoursTableView = UITableView()
    yoursTableView.tableFooterView = UIView() // eliminate extra separators
    yoursTableView.addSubview(refreshControl)

    emptyViewInYoursTab = setupYoursEmptyView()

    yoursActivityIndicator = CommonUI.appActivityIndicator()

    let view = UIView()
    view.addSubview(yoursTableView)
    view.addSubview(emptyViewInYoursTab)
    view.addSubview(yoursActivityIndicator)

    yoursTableView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }

    emptyViewInYoursTab.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }

    yoursActivityIndicator.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
    }

    return view
  }

  fileprivate func setupYoursEmptyView() -> UIView {
    let welcomeLabel = CommonUI.pageTitleLabel(text: "WELCOME TO BITMARK!")
    welcomeLabel.textColor = .mainBlueColor

    let descriptionLabel = CommonUI.descriptionLabel(text: "Register, track, and trade property rights for your digital assets.")

    let contentView = UIView()
    contentView.addSubview(welcomeLabel)
    contentView.addSubview(descriptionLabel)

    welcomeLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    descriptionLabel.snp.makeConstraints { (make) in
      make.top.equalTo(welcomeLabel.snp.bottom).offset(28)
      make.leading.trailing.equalToSuperview()
    }

    createFirstProperty = CommonUI.blueButton(title: "CREATE FIRST PROPERTY")

    let view = UIView()
    view.isHidden = true
    view.addSubview(contentView)
    view.addSubview(createFirstProperty)

    contentView.snp.makeConstraints { (make) in
      make.top.equalToSuperview().offset(25)
      make.leading.equalToSuperview().offset(20)
      make.trailing.equalToSuperview().offset(-20)
    }

    createFirstProperty.snp.makeConstraints { (make) in
      make.top.equalTo(contentView.snp.bottom).offset(25)
      make.leading.trailing.bottom.equalToSuperview()
    }

    return view
  }
}
