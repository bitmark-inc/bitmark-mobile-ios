//
//  PropertiesViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK
import Alamofire
import RealmSwift

class PropertiesViewController: UIViewController {

  // MARK: - Properties
  var segmentControl: DesignedSegmentControl!
  var yoursView: UIView!
  var globalView: DesignedWebView!

  //*** Yours Segment ***
  var refreshControl: UIRefreshControl!
  var yoursTableView: UITableView!
  var createFirstProperty: UIButton!
  var emptyViewInYoursTab: UIView!
  var yoursActivityIndicator: UIActivityIndicatorView!
  var bitmarkRs: Results<BitmarkR>!
  fileprivate var realmToken: NotificationToken?
  var networkReachabilityManager = NetworkReachabilityManager()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.title = "PROPERTIES"
    let addBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(tapToAddProperty))
    navigationItem.rightBarButtonItem = addBarButton
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
    setupEvents()

    loadData()
    setupBitmarkEventSubscription()
  }

  deinit {
    realmToken?.invalidate()
  }

  // MARK: - Data Handlers
  private func loadData() {
    yoursActivityIndicator.startAnimating()
    do {
      try BitmarkStorage.shared().firstLoad { [weak self] (error) in
        guard let self = self else { return }
        self.yoursActivityIndicator.stopAnimating()

        if let error = error {
          self.showErrorAlert(message: Constant.Error.syncBitmark)
          ErrorReporting.report(error: error)
          return
        }

        do {
          self.bitmarkRs = try BitmarkStorage.shared().getData()
        } catch {
          self.showErrorAlert(message: Constant.Error.loadBitmark)
          ErrorReporting.report(error: error)
          return
        }

        self.setupRealmObserverForLoadingBitmarks()
      }
    } catch {
      showErrorAlert(message: Constant.Error.loadBitmark)
      ErrorReporting.report(error: error)
    }
  }

  fileprivate func setupRealmObserverForLoadingBitmarks() {
    self.realmToken = self.bitmarkRs.observe({ [weak self] (changes) in
      guard let self = self else { return }
      self.yoursTableView.apply(changes: changes)
      self.setupUnreadBadge()
      self.emptyViewInYoursTab.isHidden = self.bitmarkRs.count > 0
      self.segmentControl.setBadge(self.bitmarkRs.count, forSegmentAt: 0)
    })
  }

  // MARK: - Handlers
  @objc func tapToAddProperty() {
    guard let networkReachabilityManager = networkReachabilityManager, networkReachabilityManager.isReachable else {
      Global.showNoInternetBanner()
      return
    }

    navigationController?.pushViewController(RegisterPropertyViewController())
  }

  @objc func segmentChanged(_ sender: DesignedSegmentControl) {
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
    return bitmarkRs?.count ?? 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withClass: YourPropertyCell.self)
    let bitmarkR = bitmarkRs[indexPath.row]
    cell.loadWith(bitmarkR)
    cell.setReadStyle(read: bitmarkR.read)
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let bitmarkR = bitmarkRs[indexPath.row]
    guard let assetR = bitmarkR.assetR else {
      ErrorReporting.report(message: "Missing assetId for bitmark with id " + bitmarkR.id)
      showErrorAlert(message: Constant.Error.loadData)
      return
    }
    let bitmarkDetailsVC = BitmarkDetailViewController()
    bitmarkDetailsVC.hidesBottomBarWhenPushed = true
    bitmarkDetailsVC.bitmarkR = bitmarkR
    bitmarkDetailsVC.assetR = assetR
    navigationController?.pushViewController(bitmarkDetailsVC)

    guard let cell = tableView.cellForRow(at: indexPath) as? YourPropertyCell else { return }
    cell.setReadStyle(read: true)
  }
}

// MARK: EventDelegate
extension PropertiesViewController: EventDelegate {
  @objc func syncUpdatedRecords() {
    BitmarkStorage.shared().asyncUpdateInSerialQueue() { [weak self] (_) in
      DispatchQueue.main.async {
        self?.refreshControl.endRefreshing()
      }
    }
  }
}

// MARK: - Setup Views/Events
extension PropertiesViewController {
  fileprivate func setupEvents() {
    // *** Yours Segment ***
    yoursTableView.register(cellWithClass: YourPropertyCell.self)
    yoursTableView.dataSource = self
    yoursTableView.delegate = self

    createFirstProperty.addTarget(self, action: #selector(tapToAddProperty), for: .touchUpInside)
    segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    segmentControl.sendActions(for: .valueChanged)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white
    navigationController?.navigationBar.shadowImage = UIImage()

    // *** Setup subviews ***
    segmentControl = DesignedSegmentControl(titles: ["YOURS", "GLOBAL"], width: view.frame.width, height: 38)
    yoursView = setupYoursView()
    globalView = DesignedWebView(urlString: Global.ServerURL.registry.embedInApp())

    // *** Setup UI in view ***
    view.addSubview(segmentControl)
    view.addSubview(yoursView)
    view.addSubview(globalView)

    segmentControl.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      make.height.equalTo(38)
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

    let descriptionLabel = CommonUI.descriptionLabel(text: """
      Bitmark is the property system for establishing value and legal control over the world’s data. \
      Our mission is to define digital property, defend it, and make it economically divisible.

      Register, track, and trade property rights for your digital assets.
      """)

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
      make.top.leading.trailing.equalToSuperview()
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 0, right: 20))
    }

    createFirstProperty.snp.makeConstraints { (make) in
      make.top.equalTo(contentView.snp.bottom).offset(25)
      make.leading.trailing.bottom.equalToSuperview()
    }

    return view
  }

  fileprivate func setupUnreadBadge() {
    tabBarItem.badgeValue = BitmarkStorage.shared().hasUnread() ? "●" : nil
    tabBarItem.badgeColor = .clear
    tabBarItem.setBadgeTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.red], for: .normal)
  }
}
