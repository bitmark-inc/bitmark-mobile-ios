//
//  SuspendedViewController.swift
//  Bitmark
//
//  Created by Thuyen Truong on 7/19/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

// block user screen when there are critical issue need to be done firstly
class SuspendedViewController: UIViewController {
  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    setupViews()
  }
}

// MARK: - Setup Views
// TODO: Update Design UI
extension SuspendedViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let label = CommonUI.descriptionLabel(text: "There are critical issue happening. We are checking and come back to you soon.")
    let mainView = UIView()
    mainView.addSubview(label)

    label.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }

    // *** Setup UI in view ***
    view.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20))
    }
  }
}
