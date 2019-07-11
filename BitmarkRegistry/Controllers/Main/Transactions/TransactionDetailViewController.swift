//
//  TransactionDetailViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/6/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK

class TransactionDetailViewController: UIViewController {

  // MARK: - Properties
  var transaction: Transaction!
  var mainView: DesignedWebView!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "REGISTRY"

    setupViews()
    doWhenConnectedNetwork { mainView.loadWeb() }
  }

  // MARK: Data Handlers
  fileprivate func extractURL() -> String {
    if transaction.isTransferTx() {
      return Global.ServerURL.registry + "/transaction/" + transaction.id
    } else {
      guard let asset = Global.findAsset(with: transaction.asset_id) else {
        return Global.ServerURL.registry
      }
      return Global.ServerURL.registry + "/issuance/\(transaction.block_number)/" + transaction.asset_id + "/\(asset.registrant)"
    }
  }
}

// MARK: - Setup Views
extension TransactionDetailViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup UI in view ***
    let txWebURL = extractURL()
    mainView = DesignedWebView(urlString: txWebURL.embedInApp())

    view.addSubview(mainView)

    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
    }
  }
}
