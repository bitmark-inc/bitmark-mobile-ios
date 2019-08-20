//
//  RecoveryPhraseViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/10/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import RxFlow
import RxCocoa

enum RecoveryPhraseSource {
  case testRecoveryPhrase
  case removeAccess
}

class RecoveryPhraseViewController: BaseRecoveryPhraseViewController, Stepper {
  var steps = PublishRelay<Step>()

  // MARK: - Properties
  var recoveryPhraseSource: RecoveryPhraseSource!
  private var recoveryPhrases = [String]()
  var testRecoveryPhraseButton: UIButton!
  var doneButton: UIButton!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()

    recoveryPhraseCollectionView.register(cellWithClass: RecoveryPhraseCell.self)
    recoveryPhraseCollectionView.delegate = self
    recoveryPhraseCollectionView.dataSource = self

    loadData()
  }

  // MARK: Data Handlers
  private func loadData() {
    loadRecoveryPhrases(&recoveryPhrases)
  }

  // MARK: - Handlers
  @objc func moveToTestRecoveryPhrase(_ sender: UIButton) {
    switch recoveryPhraseSource! {
    case .testRecoveryPhrase:
      steps.accept(BitmarkStep.testRecoveryPhrase)
    case .removeAccess:
      steps.accept(BitmarkStep.testRecoveryPhraseToRemoveAccess)
    }
  }

  @objc func doneHandler(_ sender: UIButton) {
    steps.accept(BitmarkStep.viewRecoveryPhraseIsComplete)
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

// MARK: - Setup Views/Events
extension RecoveryPhraseViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    let descriptionLabel = CommonUI.descriptionLabel(text: "recoveryPhrases_Description".localized(tableName: "Phrase"))
    descriptionLabel.lineHeightMultiple(1.2)

    let mainScrollView = UIScrollView()
    mainScrollView.addSubview(descriptionLabel)
    mainScrollView.addSubview(recoveryPhraseCollectionView)

    descriptionLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
          .inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }

    recoveryPhraseCollectionView.snp.makeConstraints { (make) in
      make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
      make.width.equalToSuperview().offset(-40)
      make.leading.trailing.bottom.equalToSuperview()
          .inset(UIEdgeInsets(top: 0, left: 20, bottom: 25, right: 20))
    }

    let buttonsGroupStackView = setupbuttonsGroup()

    // *** Setup UI in view ***
    view.addSubview(mainScrollView)
    view.addSubview(buttonsGroupStackView)

    mainScrollView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 0, bottom: 25, right: 0))
    }

    buttonsGroupStackView.snp.makeConstraints { (make) in
      make.top.equalTo(mainScrollView.snp.bottom)
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }
  }

  fileprivate func setupbuttonsGroup() -> UIStackView {
    switch recoveryPhraseSource! {
    case .testRecoveryPhrase:
      testRecoveryPhraseButton = CommonUI.blueButton(title: "TestRecoveryPhrase".localized().localizedUppercase)
      doneButton = CommonUI.lightButton(title: "Done".localized().localizedUppercase)
      testRecoveryPhraseButton.addTarget(self, action: #selector(moveToTestRecoveryPhrase), for: .touchUpInside)
      doneButton.addTarget(self, action: #selector(doneHandler), for: .touchUpInside)
      return UIStackView(arrangedSubviews: [testRecoveryPhraseButton, doneButton], axis: .vertical)
    case .removeAccess:
      doneButton = CommonUI.blueButton(title: "Done".localized().localizedUppercase)
      doneButton.addTarget(self, action: #selector(moveToTestRecoveryPhrase), for: .touchUpInside)
      return UIStackView(arrangedSubviews: [doneButton], axis: .vertical)
    }
  }
}
