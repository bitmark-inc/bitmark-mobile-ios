//
//  DesignedSegmentControl.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/16/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//  Reference: https://medium.com/@pleelaprasad/creating-a-custom-segmented-control-in-swift-10fede366da1
//

import UIKit

class DesignedSegmentControl: UIControl {

  // MARK: - Properties
  var segmentButtons = [UIButton]()
  var selectorBar: UIView!
  var selectedSegmentIndex = 0
  var segmentTitles: [String]!

  // MARK: - Init
  init(titles: [String], width: CGFloat, height: CGFloat) {
    self.segmentTitles = titles
    super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
    setupViews()

    // set first button as default selected segment
    segmentButtons.first?.sendActions(for: .touchUpInside)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Handlers
  @objc func buttonTapped(button: UIButton) {
    for (segmentButtonIndex, segmentButton) in segmentButtons.enumerated() {
      if segmentButton == button {
        selectedSegmentIndex = segmentButtonIndex
        segmentButton.isSelected = true
        segmentButton.backgroundColor = .white

        let  selectorStartPosition = frame.width / CGFloat(segmentButtons.count) * CGFloat(segmentButtonIndex)
        selectorBar.frame.origin.x = selectorStartPosition
      } else {
        segmentButton.isSelected = false
        segmentButton.backgroundColor = .backgroundNavBar
      }
    }

    sendActions(for: .valueChanged)
  }

  // MARK: - Setup Views/Events
  func setupViews() {
    for segmentTitle in segmentTitles {
      let button = UIButton(type: .system)
      button.backgroundColor = .backgroundNavBar
      button.shadowOpacity = 0.15
      button.titleLabel?.font = UIFont(name: "Avenir-Black", size: 14)
      button.setTitle(segmentTitle, for: .normal)
      button.setTitleColor(.silver, for: .normal)
      button.setTitleColor(.black, for: .selected)
      button.addTarget(self, action: #selector(buttonTapped(button:)), for: .touchUpInside)
      segmentButtons.append(button)
    }

    // Create a StackView
    let stackView = UIStackView(
      arrangedSubviews: segmentButtons,
      axis: .horizontal, spacing: 0, alignment: .fill, distribution: .fillEqually
    )
    addSubview(stackView)

    let selectorWidth = frame.width / CGFloat(segmentTitles.count)
    selectorBar = UIView.init(frame: CGRect.init(x: 0, y: 0, width: selectorWidth, height: 3.0))
    selectorBar.backgroundColor = .mainBlueColor
    addSubview(selectorBar)

    stackView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }
  }
}
