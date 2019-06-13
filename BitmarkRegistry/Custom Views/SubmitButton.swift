//
//  SubmitButton.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/12/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class SubmitButton: UIButton {
  var topLine: UIView!
  override var isEnabled: Bool {
    didSet {
      topLine.backgroundColor = isEnabled ? .mainBlueColor : .silver
    }
  }

  required init(title: String, isEnabled: Bool = false) {
    super.init(frame: .zero)
    setupViews()

    setTitle(title.uppercased(), for: .normal)
    self.isEnabled = isEnabled
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    setTitleColor(.mainBlueColor, for: .normal)
    setTitleColor(.silver, for: .disabled)
    backgroundColor = .wildSand
    titleLabel?.font = UIFont(name: "Avenir-Black", size: 16)

    topLine = UIView()
    topLine.backgroundColor = .silver

    addSubview(topLine)

    topLine.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
      make.height.equalTo(3)
    }

    snp.makeConstraints { (make) in
      make.height.equalTo(45)
    }
  }
}
