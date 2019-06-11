//
//  RecoveryPhraseViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/10/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class RecoveryPhraseViewController: UIViewController {

  // MARK: - Properties
  private var recoveryPhrases = [String]()

  private let sectionInsets = UIEdgeInsets(top: 5.0, left: 10.0, bottom: 0.0, right: 0.0)
  private let collectionViewPadding: CGFloat = 40.0
  private let heightPerRecoveryPhraseItem: CGFloat = 22.0
  private let screenHeightLimitationForRecoveryPhase: CGFloat = 600
  private var columns: CGFloat!
  let numberOfPhrases = 12

  let descriptionLabel: UILabel = {
    return CommonUI.descriptionLabel(text: "Please write down your recovery phrase in the exact sequence below:")
                   .lineHeightMultiple(1.2)

  }()

  lazy var recoveryPhraseCollectionView: UICollectionView = {
    let flowlayout = UICollectionViewFlowLayout()
    flowlayout.scrollDirection = .horizontal
    let collectionView = UICollectionView(frame: view.frame, collectionViewLayout: flowlayout)
    collectionView.backgroundColor = .clear
    collectionView.register(cellWithClass: RecoveryPhraseCell.self)
    collectionView.delegate = self
    collectionView.dataSource = self
    return collectionView
  }()

  let testRecoveryPhraseButton: UIButton = {
    let button = CommonUI.blueButton(title: "TEST RECOVERY PHRASE")
    return button
  }()

  lazy var doneButton: UIButton = {
    let button = CommonUI.lightButton(title: "DONE")
    button.addAction(for: .touchUpInside, { [unowned self] in
      self.navigationController?.popToRootViewController(animated: true)
    })
    return button
  }()

  lazy var buttonsGroupStackView: UIStackView = {
    return UIStackView(
      arrangedSubviews: [testRecoveryPhraseButton, doneButton],
      axis: .vertical,
      spacing: 0.0,
      alignment: .fill,
      distribution: .fill
    )
  }()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "RECOVERY PHRASE"
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()

    loadData()
  }

  // MARK: - Layout Handlers
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // adjust number of columns: 2 columns for iphone 4'; other should be 1 column
    columns = view.frame.height > screenHeightLimitationForRecoveryPhase ? 1 : 2
    recoveryPhraseCollectionView.snp.makeConstraints { (make) in
      make.height.equalTo(CGFloat(numberOfPhrases) / columns * (heightPerRecoveryPhraseItem + sectionInsets.top))
    }
  }

  // MARK: Data Handlers
  private func loadData() {
    do {
      recoveryPhrases = try Global.currentAccount!.getRecoverPhrase(language: .english)
    } catch let e {
      showErrorAlert(message: e.localizedDescription)
    }
  }
}

// MARK: - UICollectionViewDataSource
extension RecoveryPhraseViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return recoveryPhrases.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withClass: RecoveryPhraseCell.self, for: indexPath)
    cell.setData(numericOrder: indexPath.row + 1, phrase: recoveryPhrases[indexPath.row])
    return cell
  }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension RecoveryPhraseViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let paddingSpace = sectionInsets.left * (columns - 1) + collectionViewPadding
    let availableWidth = view.frame.width - paddingSpace
    let widthPerItem = availableWidth / columns
    return CGSize(width: widthPerItem, height: heightPerRecoveryPhraseItem)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.top
  }
}

// MARK: - Setup Views
extension RecoveryPhraseViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let mainView = UIView()
    mainView.addSubview(descriptionLabel)
    mainView.addSubview(recoveryPhraseCollectionView)

    descriptionLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    recoveryPhraseCollectionView.snp.makeConstraints { (make) in
      make.top.equalTo(descriptionLabel.snp.bottom).offset(25)
      make.leading.trailing.equalToSuperview()
    }

    // *** Setup UI in view ***
    view.addSubview(mainView)
    view.addSubview(buttonsGroupStackView)

    mainView.snp.makeConstraints { (make) in
      make.top.equalTo(view.safeAreaLayoutGuide).offset(25)
      make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
      make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-20)
    }

    buttonsGroupStackView.snp.makeConstraints { (make) in
      make.top.equalTo(mainView.snp.bottom)
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }
  }
}
