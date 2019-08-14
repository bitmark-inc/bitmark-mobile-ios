//
//  AccountDetailViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/19/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class AccountDetailViewController: UIViewController {

  // MARK: - Properties
  var accountNumber: String!
  var mainView: DesignedWebView!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Registry".localized().localizedUppercase

    setupViews()
    mainView.loadWeb()
  }
}

// MARK: - Setup Views
extension AccountDetailViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup UI in view ***
    let txWebURL = Global.ServerURL.registry + "/account/" + accountNumber
    mainView = DesignedWebView(urlString: txWebURL.embedInApp())

    view.addSubview(mainView)

    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
    }
  }
}
