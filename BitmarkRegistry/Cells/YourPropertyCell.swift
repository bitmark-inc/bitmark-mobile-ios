//
//  YourPropertyCell.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/16/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK
import RxSwift

class YourPropertyCell: UITableViewCell {

  // MARK: - Properties
  let dateLabel = UILabel()
  let assetNameLabel = UILabel()
  let issuerLabel = UILabel()
  let thumbnailImageView = UIImageView()
  let disposeBag = DisposeBag()

  // MARK: - Init
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Handlers
  func loadWith(_ bitmarkR: BitmarkR) {
    assetNameLabel.text = bitmarkR.assetR?.name
    if let confirmedAt = bitmarkR.confirmedAt {
      dateLabel.text = CustomUserDisplay.datetime(confirmedAt)
    } else {
      dateLabel.text = statusInWord(status: bitmarkR.status)
    }
    issuerLabel.text = CustomUserDisplay.accountNumber(bitmarkR.issuer)

    guard let assetR = bitmarkR.assetR else { return }
    if assetR.isPochangMusic() {
      loadMusicThumbnail(assetId: assetR.id)
      if let composer = assetR.composer() {
        issuerLabel.text = composer
      }
    } else if let assetType = assetR.assetType {
      thumbnailImageView.image = AssetType(rawValue: assetType)?.thumbnailImage()
    }
  }

  // Get music thumbnail from server
  fileprivate func loadMusicThumbnail(assetId: String) {
    MusicService.assetThumbnail(assetId: assetId)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] (image) in
        self?.thumbnailImageView.image = image
        }, onError: { (error) in
          Global.log.error(error)
          ErrorReporting.report(error: error)
      })
      .disposed(by: disposeBag)
  }
}

// MARK: - Setup Views
extension YourPropertyCell {
  func setReadStyle(read: Bool) {
    let viewColor: UIColor = read ? .black : .mainBlueColor
    dateLabel.textColor = viewColor
    assetNameLabel.textColor = viewColor
    issuerLabel.textColor = viewColor
  }

  fileprivate func statusInWord(status: String) -> String {
    switch BitmarkStatus(rawValue: status)! {
    case .issuing:
      return "Registering...".localized().localizedUppercase
    case .transferring:
      return "Incoming...".localized().localizedUppercase
    default:
      return ""
    }
  }

  fileprivate func setupViews() {
    separatorInset = UIEdgeInsets.zero
    layoutMargins = UIEdgeInsets.zero
    selectionStyle = .none

    // *** Setup subviews ***
    dateLabel.font = UIFont(name: Constant.andaleMono, size: 13)
    assetNameLabel.font = UIFont(name: "Avenir-Black", size: 14)
    issuerLabel.font = UIFont(name: Constant.andaleMono, size: 13)

    let stackView = UIStackView(
      arrangedSubviews: [dateLabel, assetNameLabel, issuerLabel],
      axis: .vertical, spacing: 10)

    thumbnailImageView.contentMode = .scaleAspectFit

    // *** Setup UI in view ***
    addSubview(stackView)
    addSubview(thumbnailImageView)
    stackView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
          .inset(UIEdgeInsets(top: 18, left: 27, bottom: 18, right: 27))
    }

    thumbnailImageView.snp.makeConstraints { (make) in
      make.leading.greaterThanOrEqualToSuperview()
      make.trailing.equalToSuperview().offset(-20)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(60)
    }
  }
}
