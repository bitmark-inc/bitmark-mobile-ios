//
//  AuthenticationViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 9/3/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
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
      navigateNextOnboardingStepFromBiometricStep(steps, disposeBag)
      return
    }

    if currentDeviceEvaluatePolicyType == .passcode {
      steps.accept(BitmarkStep.askingPasscodeAuthentication)
    } else {
      steps.accept(BitmarkStep.askingBiometricAuthentication)
    }
  }

  func navigateNextOnboardingStepFromBiometricStep(_ steps: PublishRelay<Step>, _ disposeBag: DisposeBag) {
    guard let currentAccount = Global.currentAccount else { return }

    if let _ = KeychainStore.getiCloudSettingFromKeychain(currentAccount.getAccountNumber()) {
      saveAccountAndProcess(steps, disposeBag)
      steps.accept(BitmarkStep.userIsLoggedIn)
    } else {
      steps.accept(BitmarkStep.askingiCloudSetting)
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
            if let isiCloudEnable = Global.iCloudEnable {
              try KeychainStore.saveiCloudSetting(currentAccount.getAccountNumber(), isEnable: isiCloudEnable)
            }
            try iCloudService.shared.setupDataFile()
            DispatchQueue.global(qos: .utility).async {
              iCloudService.shared.migrateFileData()
            }
            AccountDependencyService.shared.requestJWTAndIntercomAndAPNSHandler()

            steps.accept(BitmarkStep.userIsLoggedIn)
          } catch {
            ErrorReporting.report(error: error)
            self.navigationController?.viewControllers = [SuspendedViewController()]
          }
        },
        onError: { [weak self] (_) in
          self?.showErrorAlert(message: "keychainStore".localized(tableName: "Error"))
      })
      .disposed(by: disposeBag)
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
