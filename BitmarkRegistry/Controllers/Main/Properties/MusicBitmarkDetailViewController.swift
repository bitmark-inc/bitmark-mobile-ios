 //
//  MusicBitmarkDetailViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/14/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import SnapKit
import WebKit
import RxSwift
import Alamofire
import RxFlow
import RxCocoa

class MusicBitmarkDetailViewController: UIViewController, Stepper {
  var steps = PublishRelay<Step>()

  // MARK: - Properties
  var bitmarkR: BitmarkR!
  var assetR: AssetR!
  lazy var assetFileService = {
    return AssetFileService(owner: Global.currentAccount!, assetId: assetR.id)
  }()
  var waitingScreen: UIView!
  var activityIndicator: UIActivityIndicatorView!
  var closeButton: UIButton!
  var musicWebView: WKWebView!
  var bitmarkDetailView: UIView!
  var bitmarkDetailViewTapGesture: UITapGestureRecognizer!
  var viewBitmarkOptionsBtn: UIButton!
  var authenticatingTransferBtn: UIButton!
  var bitmarkDetailViewHeightConstraint: Constraint!
  var viewBitmarkOptionsHeightConstraint: Constraint!
  var authenticatingTransferBtnHeightConstraint: Constraint!
  let disposeBag = DisposeBag()
  var networkReachabilityManager = NetworkReachabilityManager()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
    setupEvents()
    loadData()
    markRead()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = true
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.isNavigationBarHidden = false
  }

  // MARK: - Load Data
  fileprivate func markRead() {
    do {
      try BitmarkStorage.shared().markRead(for: bitmarkR)
    } catch {
      showErrorAlert(message: Constant.Error.markReadForBitmark)
    }
  }

  fileprivate func loadData() {
    guard let networkReachabilityManager = networkReachabilityManager, networkReachabilityManager.isReachable else {
      Global.showNoInternetBanner()
      return
    }

    activityIndicator.startAnimating()
    let assetId = assetR.id

    if let _ = bitmarkR.confirmedAt {
      authenticatingTransferBtn.isHidden = true
    } else {
      viewBitmarkOptionsBtn.isHidden = true
    }

    // *** Load Music Webview ***
    MusicService.assetInfo(assetId: assetId)
      .map({ (claimingAssetInfo) -> URLRequest in
        return URLRequest(urlString: Global.ServerURL.mobile + "/api/claim_requests_view/" + assetId + "?"
            + "total=\(claimingAssetInfo.limitedEdition)&"
            + "remaining=\(claimingAssetInfo.totalEditionLeft)&"
            + "edition_number=$")!
      })
      .subscribe(
        onNext: { [weak self] (musicRequest) in
          self?.musicWebView.load(musicRequest)
          },
        onError: { (error) in
          Global.log.error(error)
          ErrorReporting.report(error: error)
        })
      .disposed(by: disposeBag)
  }

  // MARK: - Handlers
  @objc func tapToViewBitmarkDetails(_ sender: UIButton) {
    steps.accept(BitmarkStep.viewRegistryBitmarkDetails(bitmarkId: bitmarkR.id))
  }

  @objc func tapToViewBitmarkOptions(_ sender: UIButton) {
    let alertController = UIAlertController(title: "", message: "Bitmark Options", preferredStyle: .actionSheet)
    alertController.addAction(title: "Play on Streaming Platform", handler: tapToPlayOnStreamingPlatform)
    alertController.addAction(title: "Download Property", handler: tapToDownloadProperty)
    alertController.addAction(title: "Transfer Ownership", handler: tapToTransferOwnership)
    alertController.addAction(title: "Cancel", style: .cancel)
    present(alertController, animated: true, completion: nil)
  }

  @objc func tapToPlayOnStreamingPlatform(_ sender: UIAlertAction) {
    guard let playLink = assetR.metadata.first(where: { $0.key == "playlink"} )?.value,
          let playLinkURL = URL(string: playLink) else { return }
    UIApplication.shared.open(playLinkURL)
  }

  @objc func tapToDownloadProperty(_ sender: UIAlertAction) {
    showIndicatorAlert(message: Constant.Message.preparingToExport) { (selfAlert) in
      self.assetFileService.getDownloadedFileURL(assetFilename: self.assetR.filename)
        .subscribe(
          onNext: { (downloadedFileURL) in
            selfAlert.dismiss(animated: true, completion: { [weak self] in
              guard let self = self else { return }
              let shareVC = UIActivityViewController(activityItems: [downloadedFileURL], applicationActivities: [])
              self.present(shareVC, animated: true)
              self.assetR.updateAssetFileInfo(downloadedFileURL.path)
            })
        },
          onError: { _ in
            selfAlert.dismiss(animated: true, completion: { [weak self] in
              self?.showErrorAlert(message: "noReadyToDownload".localized(tableName: "Error"))
            })
        })
        .disposed(by: self.disposeBag)
    }
  }

  @objc func tapToTransferOwnership(_ sender: UIAlertAction) {
    steps.accept(BitmarkStep.viewTransferBitmark(bitmarkId: bitmarkR.id, assetR: assetR))
  }
}

 // MARK: - WKNavigationDelegate, UIScrollViewDelegate
extension MusicBitmarkDetailViewController: WKNavigationDelegate, UIScrollViewDelegate {
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    activityIndicator.stopAnimating()
    waitingScreen.isHidden = true
    musicWebView.scrollView.delegate = self
  }

  // animate up/down bitmarkDetailView
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let bottomY = scrollView.contentSize.height - scrollView.frame.size.height
    if scrollView.contentOffset.y >= bottomY {
      UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
        self.bitmarkDetailViewHeightConstraint.update(offset: 190)
        self.viewBitmarkOptionsHeightConstraint.update(offset: 45)
        self.authenticatingTransferBtnHeightConstraint.update(offset: 45)

        self.view.layoutIfNeeded()
      })
    } else if scrollView.contentOffset.y <= bottomY - 100 {
      UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
        self.bitmarkDetailViewHeightConstraint.update(offset: 0)
        self.viewBitmarkOptionsHeightConstraint.update(offset: 0)
        self.authenticatingTransferBtnHeightConstraint.update(offset: 0)
        self.view.layoutIfNeeded()
      })
    }
  }
}

// MARK: - Setup Views/Events
extension MusicBitmarkDetailViewController {
  fileprivate func setupEvents() {
    closeButton.addAction(for: .touchUpInside) { [weak self] in
      self?.steps.accept(BitmarkStep.viewMusicBitmarkDetailsIsComplete)
    }
    viewBitmarkOptionsBtn.addTarget(self, action: #selector(tapToViewBitmarkOptions), for: .touchUpInside)
    bitmarkDetailViewTapGesture.addTarget(self, action: #selector(tapToViewBitmarkDetails))
  }

  fileprivate func setupViews() {
    // *** Setup subviews ***
    view.backgroundColor = .black

    waitingScreen = UIView()
    waitingScreen.backgroundColor = .black
    activityIndicator = CommonUI.appActivityIndicator()
    waitingScreen.addSubview(activityIndicator)

    activityIndicator.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
    }

    musicWebView = WKWebView()
    musicWebView.navigationDelegate = self

    closeButton = UIButton(imageName: "close-music-view")
    bitmarkDetailView = setupBitmarkDetailsView()

    // *** Setup UI in view ***
    view.addSubview(musicWebView)
    view.addSubview(waitingScreen)
    view.addSubview(closeButton)
    view.addSubview(bitmarkDetailView)

    musicWebView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
    }

    waitingScreen.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
    }

    closeButton.snp.makeConstraints { (make) in
      make.top.leading.equalTo(view.safeAreaLayoutGuide).offset(22)
    }

    bitmarkDetailView.snp.makeConstraints { (make) in
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
      bitmarkDetailViewHeightConstraint = make.height.equalTo(0).constraint
    }
  }

  fileprivate func setupBitmarkDetailsView() -> UIView {
    let miniLogoImageView = UIImageView(image: UIImage(named: "mini-logo"))
    miniLogoImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    let securedByBitmarkTitle = UIStackView(arrangedSubviews: [miniLogoImageView, infoLabel(text: "secured by bitmark".uppercased())], axis: .horizontal, spacing: 5)

    let blackLine = UIView()
    blackLine.backgroundColor = .black
    let prefixPlusIcon = UIView()
    prefixPlusIcon.addSubview(blackLine)

    blackLine.snp.makeConstraints { (make) in
      make.height.equalTo(4)
      make.leading.trailing.centerY.equalToSuperview()
    }

    let plusIcon = UIImageView(image: UIImage(named: "music-bitmark-+")!)

    let separateView = UIStackView(arrangedSubviews: [prefixPlusIcon, plusIcon], axis: .horizontal, spacing: 10)

    let assetIdView = infoLabel(text: "ASSET ID: " + assetR.id)
    let dateIssuance = infoLabel(text: "DATE OF ISSUANCE: " + (CustomUserDisplay.date(assetR.createdAt) ?? ""))

    let bitmarkDetailsDataView = UIStackView(
      arrangedSubviews: [securedByBitmarkTitle, separateView, assetIdView, dateIssuance],
      axis: .vertical, spacing: 8
    )
    bitmarkDetailViewTapGesture = UITapGestureRecognizer()
    bitmarkDetailsDataView.addGestureRecognizer(bitmarkDetailViewTapGesture)

    setupViewBitmarkOptionsBtn()
    setupAuthenticatingTransferBtn()

    let view = UIView()
    view.backgroundColor = .white
    view.addSubview(bitmarkDetailsDataView)
    view.addSubview(viewBitmarkOptionsBtn)
    view.addSubview(authenticatingTransferBtn)

    bitmarkDetailsDataView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
        .inset(UIEdgeInsets(top: 25, left: 15, bottom: 20, right: 15))
    }

    viewBitmarkOptionsBtn.snp.makeConstraints { (make) in
      make.top.equalTo(bitmarkDetailsDataView.snp.bottom).offset(15)
      make.leading.trailing.bottom.equalToSuperview()
        .inset(UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15))
    }

    authenticatingTransferBtn.snp.makeConstraints { (make) in
      make.edges.equalTo(viewBitmarkOptionsBtn)
    }

    return view
  }

  fileprivate func setupViewBitmarkOptionsBtn() {
    viewBitmarkOptionsBtn = musicBitmarkBtn()
    viewBitmarkOptionsBtn.setTitle("VIEW BITMARK OPTIONS", for: .normal)
    viewBitmarkOptionsBtn.setTitleColor(.mainBlueColor, for: .normal)

    viewBitmarkOptionsBtn.snp.makeConstraints { (make) in
      viewBitmarkOptionsHeightConstraint = make.height.equalTo(0).constraint
    }

    viewBitmarkOptionsBtn.titleLabel!.snp.makeConstraints { (make) in
      make.height.equalTo(viewBitmarkOptionsBtn)
    }
  }

  fileprivate func setupAuthenticatingTransferBtn() {
    authenticatingTransferBtn = musicBitmarkBtn()
    authenticatingTransferBtn.setTitle("AUTHENTICATING TRANSFER TO YOU...", for: .normal)
    authenticatingTransferBtn.setTitleColor(.dustyGray, for: .normal)
    authenticatingTransferBtn.isUserInteractionEnabled = false

    authenticatingTransferBtn.snp.makeConstraints { (make) in
      authenticatingTransferBtnHeightConstraint = make.height.equalTo(0).constraint
    }

    authenticatingTransferBtn.titleLabel!.snp.makeConstraints { (make) in
      make.height.equalTo(authenticatingTransferBtn)
    }
  }

  fileprivate func musicBitmarkBtn() -> UIButton {
    let btn = UIButton(type: .system)
    btn.backgroundColor = UIColor(red: 237/255, green: 240/255, blue: 244/255, alpha: 0.7)
    btn.borderColor = .seashell
    btn.borderWidth = 0.5
    btn.titleLabel?.font = UIFont(name: "Avenir-Black", size: 14)
    return btn
  }

  fileprivate func infoLabel(text: String) -> UILabel {
    let label = UILabel(text: text)
    label.font = UIFont(name: "Courier", size: 14)
    label.textColor = .emperor
    return label
  }
}
