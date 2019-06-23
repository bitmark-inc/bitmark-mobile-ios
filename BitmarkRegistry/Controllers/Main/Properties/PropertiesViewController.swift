//
//  PropertiesViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK
import WebKit

protocol BitmarkEventDelegate {
  func receiveNewBitmarks(_ newBitmarks: [Bitmark])
}

class PropertiesViewController: UIViewController {

  // MARK: - Properties
  var yoursView: UIView!
  var globalView: UIView!

  lazy var segmentControl: UISegmentedControl = {
    let segmentControl = UISegmentedControl()
    segmentControl.segmentTitles = ["YOURS", "GLOBAL"]
    segmentControl.selectedSegmentIndex = 0
    segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    return segmentControl
  }()

  //*** Yours Segment ***
  var yoursTableView: UITableView!
  var createFirstProperty: UIButton!
  var emptyViewInYoursTab: UIView!
  var yoursActivityIndicator: UIActivityIndicatorView!
  var bitmarks = [Bitmark]()
  lazy var bitmarkStorage: BitmarkStorage = {
    let bitmarkStorage = BitmarkStorage(for: Global.currentAccount!)
    bitmarkStorage.delegate = self
    return bitmarkStorage
  }()

  // *** Global Segment ***
  var webView: WKWebView!
  var backButton: UIButton!
  var forwardButton: UIButton!
  var globalActivityIndicator: UIActivityIndicatorView!
  let globalRegisterApp = Global.registryServerUrl + "?env=app"
  var didLoadWebview: Bool = false

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
  }

  // MARK: - Data Handlers
  private func loadData() {
    yoursActivityIndicator.startAnimating()
    do {
      try bitmarkStorage.firstLoad { [weak self] (bitmarks, error) in
        guard let self = self else { return }
        self.yoursActivityIndicator.stopAnimating()

        if let error = error {
          self.showErrorAlert(message: error.localizedDescription)
        }

        if let bitmarks = bitmarks {
          self.bitmarks = bitmarks

          if self.bitmarks.isEmpty {
            self.emptyViewInYoursTab.isHidden = false
          } else {
            self.emptyViewInYoursTab.isHidden = true
            self.yoursTableView.reloadData()
          }
        }
      }
    } catch let e {
      showErrorAlert(message: e.localizedDescription)
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

      if !globalActivityIndicator.isAnimating && !didLoadWebview {
        let url = URL(string: globalRegisterApp)!
        globalActivityIndicator.startAnimating()
        webView.load(URLRequest(url: url))
      }
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
extension PropertiesViewController: BitmarkEventDelegate {
  func receiveNewBitmarks(_ newBitmarks: [Bitmark]) {
    for newBitmark in newBitmarks {
      yoursTableView.beginUpdates()
      // Remove obsolete bitmark which is displaying in table
      if let index = bitmarks.firstIndexWithId(newBitmark.id) {
        bitmarks.remove(at: index)
        yoursTableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .none)
      }
      // Add new bitmark
      bitmarks.prepend(newBitmark)
      yoursTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
      yoursTableView.endUpdates()
    }
  }
}

// MARK: - WKWebView, WKNavigationDelegate
extension PropertiesViewController: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    didLoadWebview = true
    globalActivityIndicator.stopAnimating()
  }

  @objc func navigateBack(_ sender: UIButton) {
    if webView.canGoBack {
      webView.goBack()
    }
  }

  @objc func navigateForward(_ sender: UIButton) {
    if webView.canGoForward {
      webView.goForward()
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

    // *** Global Segment ***
    webView.navigationDelegate = self
    backButton.addTarget(self, action: #selector(navigateBack), for: .touchUpInside)
    forwardButton.addTarget(self, action: #selector(navigateForward), for: .touchUpInside)

    segmentControl.sendActions(for: .valueChanged)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    yoursView = setupYoursView()
    globalView = setupGlobalView()

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
    yoursTableView = UITableView()
    yoursTableView.tableFooterView = UIView() // eliminate extra separators

    emptyViewInYoursTab = setupYoursEmptyView()

    yoursActivityIndicator = UIActivityIndicatorView()
    yoursActivityIndicator.style = .whiteLarge
    yoursActivityIndicator.color = .gray

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

  fileprivate func setupGlobalView() -> UIView {
    webView = WKWebView()

    backButton = UIButton(type: .system)
    backButton.setImage(UIImage(named: "back-arrow"), for: .normal)
    backButton.contentMode = .scaleAspectFit
    backButton.tintColor = .silver

    forwardButton = UIButton(type: .system)
    forwardButton.setImage(UIImage(named: "forward-arrow"), for: .normal)
    forwardButton.contentMode = .scaleAspectFit
    forwardButton.tintColor = .silver

    let navigationButtons = UIStackView(
      arrangedSubviews: [backButton, forwardButton],
      axis: .horizontal, spacing: 100
    )

    let coverNavigationButtonsView = UIView()
    coverNavigationButtonsView.backgroundColor = .alabaster
    coverNavigationButtonsView.addSubview(navigationButtons)

    navigationButtons.snp.makeConstraints { (make) in
      make.height.equalTo(45)
      make.centerX.equalToSuperview()
    }

    globalActivityIndicator = UIActivityIndicatorView()
    globalActivityIndicator.style = .whiteLarge
    globalActivityIndicator.color = .gray

    let view = UIView()
    view.addSubview(webView)
    view.addSubview(coverNavigationButtonsView)
    view.addSubview(globalActivityIndicator)

    webView.snp.makeConstraints { $0.edges.equalToSuperview() }

    coverNavigationButtonsView.snp.makeConstraints { (make) in
      make.height.equalTo(45)
      make.leading.trailing.bottom.equalToSuperview()
    }

    globalActivityIndicator.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
    }

    return view
  }
}
