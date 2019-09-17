//
//  RegistryDetailViewController.swift
//  Bitmark
//
//  Created by Thuyen Truong on 7/19/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

class RegistryDetailViewController: UIViewController {

  // MARK: - Properties
  var query: String!
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
extension RegistryDetailViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup UI in view ***
    let txWebURL = Global.ServerURL.registry + query
    mainView = DesignedWebView(urlString: txWebURL.embedInApp())

    view.addSubview(mainView)

    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
    }
  }
}
