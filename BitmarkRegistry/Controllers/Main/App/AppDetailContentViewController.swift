//
//  AppDetailContentViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/12/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class AppDetailContentViewController: UIViewController {

  // MARK: - Properties
  var appDetailContent: AppDetailContent!
  var mainView: DesignedWebView!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = appDetailContent.title()

    setupViews()
    mainView.loadWeb()
  }
}

// MARK: - Setup Views
extension AppDetailContentViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup UI in view ***
    let txWebURL = appDetailContent.contentLink()
    print(txWebURL.embedInApp())
    mainView = DesignedWebView(urlString: txWebURL.embedInApp(), hasNavigation: false)

    view.addSubview(mainView)

    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
    }
  }
}
