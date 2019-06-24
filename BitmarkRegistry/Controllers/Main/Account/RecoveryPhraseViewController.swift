//
//  RecoveryPhraseViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/10/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

enum RecoveryPhraseSource {
  case TestRecoveryPhrase
  case RemoveAccess
}

class RecoveryPhraseViewController: BaseRecoveryPhraseViewController {

  // MARK: - Properties
  var recoveryPhraseSource: RecoveryPhraseSource!
  lazy var screenTitle: String = {
    switch recoveryPhraseSource! {
    case .TestRecoveryPhrase:
      return "RECOVERY PHRASE"
    case .RemoveAccess:
      return "WRITE DOWN RECOVERY PHRASE"
    }
  }()

  private var recoveryPhrases = [String]()
  var testRecoveryPhraseButton: UIButton!
  var doneButton: UIButton!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = screenTitle
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
    let testRecoveryPhraseVC = TestRecoveryPhraseViewController()
    testRecoveryPhraseVC.recoveryPhraseSource = recoveryPhraseSource
    navigationController?.pushViewController(testRecoveryPhraseVC)
  }

  @objc func doneHandler(_ sender: UIButton) {
    navigationController?.popToRootViewController(animated: true)
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
    let descriptionLabel = CommonUI.descriptionLabel(text: "Please write down your recovery phrase in the exact sequence below:")
    descriptionLabel.lineHeightMultiple(1.2)

    let mainView = UIView()
    mainView.addSubview(descriptionLabel)
    mainView.addSubview(recoveryPhraseCollectionView)

    descriptionLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    recoveryPhraseCollectionView.snp.makeConstraints { (make) in
      make.top.equalTo(descriptionLabel.snp.bottom).offset(15)
      make.leading.trailing.equalToSuperview()
    }

    let buttonsGroupStackView = setupbuttonsGroup()

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

  fileprivate func setupbuttonsGroup() -> UIStackView {
    switch recoveryPhraseSource! {
    case .TestRecoveryPhrase:
      testRecoveryPhraseButton = CommonUI.blueButton(title: "TEST RECOVERY PHRASE")
      doneButton = CommonUI.lightButton(title: "DONE")
      testRecoveryPhraseButton.addTarget(self, action: #selector(moveToTestRecoveryPhrase), for: .touchUpInside)
      doneButton.addTarget(self, action: #selector(doneHandler), for: .touchUpInside)
      return UIStackView(arrangedSubviews: [testRecoveryPhraseButton, doneButton], axis: .vertical)
    case .RemoveAccess:
      doneButton = CommonUI.blueButton(title: "DONE")
      doneButton.addTarget(self, action: #selector(moveToTestRecoveryPhrase), for: .touchUpInside)
      return UIStackView(arrangedSubviews: [doneButton], axis: .vertical)
    }
  }
}
