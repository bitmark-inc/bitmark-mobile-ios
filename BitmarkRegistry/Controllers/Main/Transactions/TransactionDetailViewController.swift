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
  var transactionR: TransactionR!
  var mainView: DesignedWebView!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Registry".localized().localizedUppercase

    setupViews()
    mainView.loadWeb()
  }

  // MARK: Data Handlers
  fileprivate func extractURL() -> String {
    guard let txType = TransactionType(rawValue: transactionR.txType) else { return "" }
    switch txType {
    case .issurance:
      guard let assetR = transactionR.assetR, let blockR = transactionR.blockR else {
        return Global.ServerURL.registry
      }
      return Global.ServerURL.registry + "/issuance/\(blockR.number)/" + assetR.id + "/\(transactionR.owner)"
    case .transfer:
      return Global.ServerURL.registry + "/transaction/" + transactionR.id
    default:
      return ""
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
