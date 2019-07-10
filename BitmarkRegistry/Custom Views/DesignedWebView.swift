//
//  DesignedWebView.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 7/6/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import WebKit

/**
 Create Designed WebView: supports webview in Bitmark app
 - Components:
   - **webView**: webview which diplays content of URL.
   - **backButton**: navigate back.
   - **forwardButton**: navigate forward.
   - **activityIndicator**
 */
class DesignedWebView: UIView {

  // MARK: Properties
  let urlRequest: URLRequest!

  var webView: WKWebView!
  var backButton: UIButton!
  var forwardButton: UIButton!
  var activityIndicator: UIActivityIndicatorView!
  var didLoadWebview: Bool = false

  // MARK: - Init
  init(urlString: String) {
    self.urlRequest = URLRequest(urlString: urlString)
    super.init(frame: CGRect.zero)

    setupViews()
    setupEvents()
  }

  func loadWeb() {
    guard !(webView.isLoading || didLoadWebview) else { return }
    activityIndicator.startAnimating()
    webView.load(urlRequest)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - WKNavigationDelegate, Navigation Handlers
extension DesignedWebView: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    didLoadWebview = true
    activityIndicator.stopAnimating()
  }

  @objc func navigateBack(_ sender: UIButton) {
    if webView.canGoBack {
      webView.goBack()
    }
  }

  @objc func navigateForward(_ sender: UIButton) {
    if webView.canGoForward {
      webView.goForward()
    }
  }
}

// MARK: - Setup Views/Events
extension DesignedWebView {
  fileprivate func setupEvents() {
    webView.navigationDelegate = self
    backButton.addTarget(self, action: #selector(navigateBack), for: .touchUpInside)
    forwardButton.addTarget(self, action: #selector(navigateForward), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    webView = WKWebView()

    backButton = UIButton(type: .system)
    backButton.setImage(UIImage(named: "back-arrow"), for: .normal)
    backButton.contentMode = .scaleAspectFit
    backButton.tintColor = .silver

    forwardButton = UIButton(type: .system)
    forwardButton.setImage(UIImage(named: "forward-arrow"), for: .normal)
    forwardButton.contentMode = .scaleAspectFit
    forwardButton.tintColor = .silver

    let navigationButtons = UIStackView(
      arrangedSubviews: [backButton, forwardButton],
      axis: .horizontal, spacing: 100
    )

    let webNavButtonsView = UIView()
    webNavButtonsView.backgroundColor = .alabaster
    webNavButtonsView.addSubview(navigationButtons)

    navigationButtons.snp.makeConstraints { (make) in
      make.height.equalTo(45)
      make.centerX.equalToSuperview()
    }

    activityIndicator = CommonUI.appActivityIndicator()

    addSubview(webView)
    addSubview(webNavButtonsView)
    addSubview(activityIndicator)

    webView.snp.makeConstraints { $0.edges.equalToSuperview() }

    webNavButtonsView.snp.makeConstraints { (make) in
      make.height.equalTo(45)
      make.leading.trailing.bottom.equalToSuperview()
    }

    activityIndicator.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
    }
  }
}
