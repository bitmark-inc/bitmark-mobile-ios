//
//  TransactionsViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/24/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class TransactionsViewController: UIViewController {

  // MARK: - Properties
  var emptyView: UIView!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "TRANSACTIONS"
    setupViews()
  }

}

// MARK: - Setup Views
extension TransactionsViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    emptyView = setupEmptyView()

    let mainView = UIView()
    mainView.addSubview(emptyView)

    emptyView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }

    // *** Setup UI in view ***
    view.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20))
    }
  }

  fileprivate func setupEmptyView() -> UIView {
    let titleLabel = CommonUI.pageTitleLabel(text: "NO TRANSACTION HISTORY.")
    titleLabel.textColor = .mainBlueColor

    let descriptionLabel = CommonUI.descriptionLabel(text: "Your transaction history will be available here.")

    let view = UIView()
    view.addSubview(titleLabel)
    view.addSubview(descriptionLabel)

    titleLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    descriptionLabel.snp.makeConstraints { (make) in
      make.top.equalTo(titleLabel.snp.bottom).offset(35)
      make.leading.trailing.equalToSuperview()
    }

    return view
  }

  
}
