//
//  AppNavigationViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/13/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxFlow
import RxCocoa

class AppNavigationViewController: UIViewController, Stepper {
  var steps = PublishRelay<Step>()

  // MARK: - Properties
  let disposeBag = DisposeBag()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    navigate()
  }

  // MARK: - Handlers
  // Redirect Screen for new user / existing user
  func navigate() {
    AccountService.shared.existsCurrentAccount()
      .observeOn(MainScheduler.instance)
      .subscribe(
        onSuccess: { (isAccountExisted) in
          if isAccountExisted {
            // setup realm db & icloud
            do {
              try RealmConfig.setupDBForCurrentAccount()
              try iCloudService.shared.setupDataFile()
              DispatchQueue.global(qos: .utility).async {
                iCloudService.shared.migrateFileData()
              }
              AccountDependencyService.shared.requestJWTAndIntercomAndAPNSHandler()
            } catch {
              ErrorReporting.report(error: error)
              UIApplication.shared.keyWindow?.rootViewController = SuspendedViewController()
            }
            self.steps.accept(BitmarkStep.dashboardIsRequired)
          } else {
            self.steps.accept(BitmarkStep.onboardingIsRequired)
          }
        },
        onError: { [weak self] (error) in
          guard let self = self else { return }
          let retryAuthenticationAlert = UIAlertController(
            title: "Error".localized(),
            message: "PleaseAuthorize".localized().localizedUppercase,
            preferredStyle: .alert
          )
          retryAuthenticationAlert.addAction(title: "Retry".localized(), style: .default, handler: { [weak self] _ in self?.navigate() })
          retryAuthenticationAlert.show()
        }
      )
      .disposed(by: disposeBag)
  }
}

// MARK: - Setup Views
extension AppNavigationViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    let imageView = UIImageView(image: UIImage(named: "bitmark-logo-launch"))
    imageView.contentMode = .scaleAspectFit
    view.addSubview(imageView)

    imageView.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
      make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }
  }
}
