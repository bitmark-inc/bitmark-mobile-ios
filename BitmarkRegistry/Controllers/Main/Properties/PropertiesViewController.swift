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
  let yoursView = UIView()
  let globalView = UIView()

  lazy var segmentControl: UISegmentedControl = {
    let segmentControl = UISegmentedControl()
    segmentControl.segmentTitles = ["YOURS", "GLOBAL"]
    segmentControl.selectedSegmentIndex = 0
    segmentControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
    return segmentControl
  }()

  //*** Yours Segment ***
  var yoursTableView: UITableView!
  var yoursActivityIndicator: UIActivityIndicatorView!
  var createFirstProperty: UIButton!
  let emptyViewInYoursTab = UIView()
  var bitmarks = [Bitmark]()
  lazy var bitmarkStorage: BitmarkStorage = {
    return BitmarkStorage(for: Global.currentAccount!)
  }()

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
    default:
      break
    }
  }
}

// MARK: - UITableViewDataSource
extension PropertiesViewController: UITableViewDataSource {
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
}

// MARK: - Setup Views/Events
extension PropertiesViewController {
  fileprivate func setupEvents() {
    yoursTableView.register(cellWithClass: YourPropertyCell.self)
    yoursTableView.dataSource = self

    createFirstProperty.addTarget(self, action: #selector(tapToAddProperty), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    // ***** Yours Segment *****
    setupYoursEmptyView()

    yoursActivityIndicator = UIActivityIndicatorView()
    yoursActivityIndicator.style = .whiteLarge
    yoursActivityIndicator.color = .gray

    yoursTableView = UITableView()
    yoursTableView.tableFooterView = UIView() // eliminate extra separators

    yoursView.addSubview(yoursTableView)
    yoursView.addSubview(emptyViewInYoursTab)
    yoursView.addSubview(yoursActivityIndicator)

    yoursTableView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }

    yoursActivityIndicator.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
    }

    emptyViewInYoursTab.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }

    // *** Setup UI in view ***
    view.addSubview(segmentControl)
    view.addSubview(yoursView)

    segmentControl.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      make.height.equalTo(35)
    }

    yoursView.snp.makeConstraints { (make) in
      make.top.equalTo(segmentControl.snp.bottom)
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }
  }

  fileprivate func setupYoursEmptyView() {
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

    emptyViewInYoursTab.isHidden = true
    emptyViewInYoursTab.addSubview(contentView)
    emptyViewInYoursTab.addSubview(createFirstProperty)

    contentView.snp.makeConstraints { (make) in
      make.top.equalToSuperview().offset(25)
      make.leading.equalToSuperview().offset(20)
      make.trailing.equalToSuperview().offset(-20)
    }

    createFirstProperty.snp.makeConstraints { (make) in
      make.top.equalTo(contentView.snp.bottom).offset(25)
      make.leading.trailing.bottom.equalToSuperview()
    }
  }
}
