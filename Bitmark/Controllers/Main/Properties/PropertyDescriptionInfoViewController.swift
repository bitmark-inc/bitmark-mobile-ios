//
//  PropertyDescriptionInfoViewController.swift
//  Bitmark
//
//  Created by Thuyen Truong on 8/2/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit

class PropertyDescriptionInfoViewController: UIViewController {
  // MARK: - Properties

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "registerPropertyRights_title".localized(tableName: "Phrase").localizedUppercase

    setupViews()
  }
}

// MARK: - Setup Views
extension PropertyDescriptionInfoViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let pageTitle = CommonUI.pageTitleLabel(text: "propertyDescriptionInfo_title".localized(tableName: "Phrase").localizedUppercase)
    pageTitle.textColor = .mainBlueColor
    pageTitle.textAlignment = .center

    let descriptionText = CommonUI.descriptionLabel(text: "propertyDescriptionInfo_message".localized(tableName: "Phrase"))

    let exampleTable = UIImageView(image: UIImage(named: "property-description-example"))
    exampleTable.contentMode = .scaleAspectFit

    // *** Setup UI in view ***
    let mainView = UIScrollView()
    mainView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
    mainView.addSubview(pageTitle)
    mainView.addSubview(descriptionText)
    mainView.addSubview(exampleTable)

    pageTitle.snp.makeConstraints { (make) in
      make.top.leading.centerX.equalToSuperview()
      make.width.equalToSuperview().offset(-20)
    }

    descriptionText.snp.makeConstraints { (make) in
      make.top.equalTo(pageTitle.snp.bottom).offset(25)
      make.leading.trailing.centerX.equalToSuperview()
      make.width.equalToSuperview().offset(-20)
    }

    exampleTable.snp.makeConstraints { (make) in
      make.top.equalTo(descriptionText.snp.bottom).offset(30)
      make.leading.trailing.centerX.bottom.equalToSuperview()
    }

    view.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 0))
    }
  }
}
