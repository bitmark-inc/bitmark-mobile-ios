//
//  AppNavigationViewController.swift
//  Bitmark
//
//  Created by Thuyen Truong on 8/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
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
    let sharedObservbale = AccountService.shared.existsCurrentAccount().asObservable().share()

    // in case account is existing:
    // - check iCloud connection when enable
    // - setup Realm DB
    // - Request JWT, Intercom & APNS Handler
    sharedObservbale
      .filter { $0 == true }
      .ignoreElements()
      .observeOn(MainScheduler.instance)
      .subscribe(onCompleted: { [weak self] in
        guard let self = self, let currentAccountNumber = Global.currentAccount?.getAccountNumber() else { return }
        guard let iCloudSetting = KeychainStore.getiCloudSettingFromKeychain(currentAccountNumber) else {
          self.steps.accept(BitmarkStep.askingiCloudSetting)
          return
        }

        Global.isiCloudEnabled = iCloudSetting
        self.checkiCloudConnectionWhenEnable(iCloudSetting)
          .do(onCompleted: {
            try RealmConfig.setupDBForCurrentAccount()
            AccountDependencyService.shared.requestJWTAndIntercomAndAPNSHandler()
          })
          .subscribe(
            onCompleted: { [weak self] in
              self?.steps.accept(BitmarkStep.dashboardIsRequired)
            },
            onError: { (error) in
              ErrorReporting.report(error: error)
              UIApplication.shared.keyWindow?.rootViewController = SuspendedViewController()
            })
          .disposed(by: self.disposeBag)
      })
      .disposed(by: disposeBag)

    // in case existing account in keychain but can not access
    // show authentication required alert
    sharedObservbale
      .subscribe(onError: { [weak self] (_) in
        self?.showAuthenticationRequiredAlert()
      })
      .disposed(by: disposeBag)

    // in case account's not existing; redirect to onboarding screen
    sharedObservbale
      .filter { $0 == false }
      .subscribe(onNext: { (_) in
        self.steps.accept(BitmarkStep.onboardingIsRequired)
      })
      .disposed(by: disposeBag)
  }

  func checkiCloudConnectionWhenEnable(_ isiCloudSettingEnable: Bool) -> Completable {
    return Completable.create(subscribe: { (completable) -> Disposable in
      let disposable = Disposables.create()

      guard isiCloudSettingEnable else {
        completable(.completed)
        return disposable
      }

      if !iCloudService.ableToConnectiCloud() {
        self.showiCloudDisabledAlert(okHandler: { [weak self] in
          guard let self = self else { return }
          self.checkiCloudConnectionWhenEnable(true)
            .subscribe(onCompleted: {
              completable(.completed)
            })
            .disposed(by: self.disposeBag)
        })
      } else {
        completable(.completed)
      }

      return disposable
    })
  }

  func showAuthenticationRequiredAlert() {
    let currentDeviceEvaluatePolicyType = BiometricAuth().currentDeviceEvaluatePolicyType()
    let retryAuthenticationAlert = UIAlertController(
      title: "\(currentDeviceEvaluatePolicyType)_required_title".localized(tableName: "Error"),
      message: "\(currentDeviceEvaluatePolicyType)_required_message".localized(tableName: "Error"),
      preferredStyle: .alert
    )
    retryAuthenticationAlert.addAction(title: "TryAgain".localized(), style: .default, handler: { [weak self] _ in
      self?.navigate()
    })
    retryAuthenticationAlert.show()
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
