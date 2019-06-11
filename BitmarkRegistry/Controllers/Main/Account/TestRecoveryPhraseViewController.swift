//
//  TestRecoveryPhraseViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class TestRecoveryPhraseViewController: BaseRecoveryPhraseViewController {

  // MARK: - Properties
  private var recoveryPhrases = [String]()

  private let numberOfHiddenPhrases = 5
  private var hiddenPhraseIndexes = [Int]()

  let descriptionLabel: UILabel = {
    return CommonUI.descriptionLabel(text: "Tap the words to put them in the correct order for your recovery phrase:")
                   .lineHeightMultiple(1.2)

  }()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "RECOVERY PHRASE"
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()

    recoveryPhraseCollectionView.register(cellWithClass: TestRecoveryPhraseCell.self)
    recoveryPhraseCollectionView.delegate = self
    recoveryPhraseCollectionView.dataSource = self

    loadData()
  }

  // MARK: Data Handlers
  private func loadData() {
    loadRecoveryPhrases(&recoveryPhrases)
    hiddenPhraseIndexes = randomHiddenIndexes()
  }
}

// MARK: - UICollectionViewDataSource
extension TestRecoveryPhraseViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return recoveryPhrases.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withClass: TestRecoveryPhraseCell.self, for: indexPath)
    let numericOrder = indexPath.row + 1
    if hiddenPhraseIndexes.firstIndex(of: indexPath.row) != nil {
      cell.setData(numericOrder: numericOrder)
      cell.showHiddenBox()
    } else {
      cell.setData(numericOrder: numericOrder, phrase: recoveryPhrases[indexPath.row])
    }
    return cell
  }
}

// MARK: - Setup Views
extension TestRecoveryPhraseViewController {
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

    mainView.snp.makeConstraints { (make) in
      make.top.equalTo(view.safeAreaLayoutGuide).offset(25)
      make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
      make.trailing.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
    }
  }
}

// MARK: - Support Functions
extension TestRecoveryPhraseViewController {
  func randomHiddenIndexes() -> [Int] {
    var randomIndexes = [Int]()
    var availableNums = Array(0..<recoveryPhrases.count)
    for _ in 0..<numberOfHiddenPhrases {
      let randomIndex = availableNums.randomElement()!
      randomIndexes.append(randomIndex)
      availableNums.remove(at: availableNums.firstIndex(of: randomIndex)!)
    }
    return randomIndexes
  }
}
