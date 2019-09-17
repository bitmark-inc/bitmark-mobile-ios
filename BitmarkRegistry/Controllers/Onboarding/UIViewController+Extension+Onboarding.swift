//
//  AuthenticationViewController.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 9/3/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxFlow
import RxCocoa

/**
 Save Account and Process for current-user:
 - setup Realm DB & iCloud DB
 - migrate File Data
 - request JWT, Intercom and APNS
 */
extension UIViewController {

  func navigateNextOnboardingStepFromOnboardingStep(_ steps: PublishRelay<Step>, _ disposeBag: DisposeBag) {
    let currentDeviceEvaluatePolicyType = BiometricAuth().currentDeviceEvaluatePolicyType()

    guard currentDeviceEvaluatePolicyType != .none else {
      UserSetting.shared.setTouchFaceIdSetting(isEnabled: false)
      saveAccountAndProcess(steps, disposeBag)
      return
    }

    if currentDeviceEvaluatePolicyType == .passcode {
      steps.accept(BitmarkStep.askingPasscodeAuthentication)
    } else {
      steps.accept(BitmarkStep.askingBiometricAuthentication)
    }
  }

  func saveAccountAndProcess(_ steps: PublishRelay<Step>, _ disposeBag: DisposeBag) {
    guard let currentAccount = Global.currentAccount else { return }
    KeychainStore.saveToKeychain(currentAccount.seed.core)
      .observeOn(MainScheduler.instance)
      .subscribe(
        onCompleted: { [weak self] in
          guard let self = self else { return }
          do {
            // setup realm db & icloud db
            try RealmConfig.setupDBForCurrentAccount()
            AccountDependencyService.shared.requestJWTAndIntercomAndAPNSHandler()
            self.navigateNextOnboardingStepFromBiometricStep(steps, disposeBag)
          } catch {
            ErrorReporting.report(error: error)
            steps.accept(BitmarkStep.appSuspension)
          }
        },
        onError: { [weak self] (_) in
          self?.showErrorAlert(message: "keychainStore".localized(tableName: "Error"))
      })
      .disposed(by: disposeBag)
  }

  fileprivate func navigateNextOnboardingStepFromBiometricStep(_ steps: PublishRelay<Step>, _ disposeBag: DisposeBag) {
    guard let currentAccount = Global.currentAccount else { return }

    if KeychainStore.getiCloudSettingFromKeychain(currentAccount.getAccountNumber()) == nil {
      steps.accept(BitmarkStep.askingiCloudSetting)
    } else {
      steps.accept(BitmarkStep.onboardingIsComplete)
    }
  }

  func showiCloudDisabledAlert(okHandler: @escaping () -> Void) {
    let iCloudDisabledAlert = UIAlertController(
      title: "iCloudDisabled_title".localized(tableName: "Error"),
      message: "iCloudDisabled_message".localized(tableName: "Error"),
      preferredStyle: .alert
    )
    iCloudDisabledAlert.addAction(title: "OK".localized(), style: .default, handler: { (_) in okHandler() })
    iCloudDisabledAlert.show()
  }
}
