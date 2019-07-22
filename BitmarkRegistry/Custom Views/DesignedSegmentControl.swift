//
//  DesignedSegmentControl.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/16/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//  Reference: https://medium.com/@pleelaprasad/creating-a-custom-segmented-control-in-swift-10fede366da1
//

import UIKit

/**
 DesignedSegmentControl: create our own Segment Control to have ability to implement UI/functionality as design
 - supports in Properties tab.
 */
class DesignedSegmentControl: UIControl {

  // MARK: - Properties
  var segments = [UIView]()
  var segmentButtons = [UIButton]()
  var segmentBadgeLabels = [UILabel]()
  var selectorBar: UIView!
  var selectedSegmentIndex = 0
  var segmentTitles: [String]!
  let badgeLimit = 99

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
        segmentBadgeLabels[segmentButtonIndex].textColor = .black

        let  selectorStartPosition = frame.width / CGFloat(segmentButtons.count) * CGFloat(segmentButtonIndex)
        selectorBar.frame.origin.x = selectorStartPosition
      } else {
        segmentButton.isSelected = false
        segmentButton.backgroundColor = .backgroundNavBar
        segmentBadgeLabels[segmentButtonIndex].textColor = .silver
      }
    }

    sendActions(for: .valueChanged)
  }

  func setBadge(_ badge: Int, forSegmentAt index: Int) {
    let badgeText = badge > badgeLimit ? "\(badgeLimit)+" : String(badge)
    segmentBadgeLabels[index].text = "(\(badgeText))"
  }

  // MARK: - Setup Views/Events
  fileprivate func setupViews() {
    // *** Setup subviews ***
    for segmentTitle in segmentTitles {
      let button = setupSegmentButton(title: segmentTitle)
      button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
      segmentButtons.append(button)

      let badgeLabel = setupSegmentBadge()
      segmentBadgeLabels.append(badgeLabel)

      let segmentView = UIView()
      segmentView.addSubview(button)
      segmentView.addSubview(badgeLabel)
      button.snp.makeConstraints { $0.edges.equalToSuperview() }

      badgeLabel.snp.makeConstraints { (make) in
        make.centerX.equalToSuperview().offset(32)
        make.centerY.equalToSuperview().offset(1.5)
      }

      segments.append(segmentView)
    }

    // *** Setup UI in view ***
    let stackView = UIStackView(
      arrangedSubviews: segments,
      axis: .horizontal, spacing: 0, alignment: .fill, distribution: .fillEqually
    )
    setupSelectorBar()

    addSubview(stackView)
    addSubview(selectorBar)

    stackView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }
  }

  fileprivate func setupSegmentButton(title: String) -> UIButton {
    let button = UIButton(type: .system)
    button.backgroundColor = .backgroundNavBar
    button.shadowOpacity = 0.15
    button.titleLabel?.font = UIFont(name: "Avenir-Black", size: 14)
    button.setTitle(title, for: .normal)
    button.setTitleColor(.silver, for: .normal)
    button.setTitleColor(.black, for: .selected)
    button.tintColor = .clear
    return button
  }

  fileprivate func setupSegmentBadge() -> UILabel {
    let label = UILabel()
    label.font = UIFont(name: "Avenir-Black", size: 10)
    return label
  }

  fileprivate func setupSelectorBar() {
    let selectorWidth = frame.width / CGFloat(segmentTitles.count)
    selectorBar = UIView.init(frame: CGRect.init(x: 0, y: 0, width: selectorWidth, height: 3.0))
    selectorBar.backgroundColor = .mainBlueColor
  }
}
