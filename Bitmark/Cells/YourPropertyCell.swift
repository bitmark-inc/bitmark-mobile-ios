//
//  YourPropertyCell.swift
//  Bitmark
//
//  Created by Thuyen Truong on 6/16/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
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
  var notUploadiCloudView: UIView!
  fileprivate var disposeBag = DisposeBag()

  // MARK: - Init
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
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
    notUploadiCloudView.isHidden = false
    loadUploadiCloudStatus(assetR: assetR)

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
          Global.log.error(error)
      })
      .disposed(by: disposeBag)
  }
  /**
   1. when user skip to save to iCloud, hide the icon by default
   2. when filename has not existed, hide the icon by default
   3. subscribe observable to hide notUploadiCloudView when file's uploadeded to iCloud successfully
   */
  fileprivate func loadUploadiCloudStatus(assetR: AssetR) {
    // 1
    if let isiCloudEnabled = Global.isiCloudEnabled, !isiCloudEnabled {
      notUploadiCloudView.isHidden = true
    }

    // 2
    guard let assetFilename = assetR.filename else {
      notUploadiCloudView.isHidden = true
      return
    }

    // 3
    iCloudService.shared.uploadedAssetFileSubject
      .filter { $0.contains(assetFilename) }
      .subscribe(onNext: { [weak notUploadiCloudView] (_) in
        notUploadiCloudView?.isHidden = true
      })
      .disposed(by: disposeBag)
    iCloudService.shared.checkUploadiCloudStatus(assetFilename)
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

    notUploadiCloudView = setupNotUploadiCloudView()

    // *** Setup UI in view ***
    addSubview(stackView)
    addSubview(thumbnailImageView)
    addSubview(notUploadiCloudView)

    stackView.snp.makeConstraints { (make) in
      make.top.leading.trailing.bottom.equalToSuperview()
          .inset(UIEdgeInsets(top: 32, left: 27, bottom: 33, right: 27))
    }

    thumbnailImageView.snp.makeConstraints { (make) in
      make.trailing.equalToSuperview().offset(-23)
      make.centerY.equalToSuperview()
      make.width.height.equalTo(55)
    }

    notUploadiCloudView.snp.makeConstraints { (make) in
      make.top.equalTo(stackView.snp.bottom).offset(13)
      make.trailing.bottom.equalToSuperview()
          .inset(UIEdgeInsets(top: 18, left: 27, bottom: 6, right: 16))
    }
  }

  fileprivate func setupNotUploadiCloudView() -> UIView {
    let view = UIView()

    let notUploadiCloudImageView = UIImageView(image: UIImage(named: "upload-icloud-failed"))
    notUploadiCloudImageView.contentMode = .scaleAspectFit

    let notUploadiCloudLabel = UILabel(text: "notUploadiCloud".localized(tableName: "Error"))
    notUploadiCloudLabel.font = UIFont(name: Constant.andaleMono, size: 12)
    notUploadiCloudLabel.textColor = .emperor

    view.addSubview(notUploadiCloudImageView)
    view.addSubview(notUploadiCloudLabel)

    notUploadiCloudImageView.snp.makeConstraints { (make) in
      make.top.leading.bottom.equalToSuperview()
    }

    notUploadiCloudLabel.snp.makeConstraints { (make) in
      make.leading.equalTo(notUploadiCloudImageView.snp.trailing).offset(6)
      make.top.bottom.trailing.equalToSuperview()
    }
    return view
  }
}
