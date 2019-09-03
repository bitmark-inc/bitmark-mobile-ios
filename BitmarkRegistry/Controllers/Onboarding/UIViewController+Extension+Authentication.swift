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

  func navigateNextOnboardingStep(_ steps: PublishRelay<Step>, _ disposeBag: DisposeBag) {
    let currentDeviceEvaluatePolicyType = BiometricAuth().currentDeviceEvaluatePolicyType()

    guard currentDeviceEvaluatePolicyType != .none else {
      UserSetting.shared.setTouchFaceIdSetting(isEnabled: false)
      saveAccountAndProcess(steps, disposeBag)
      steps.accept(BitmarkStep.userIsLoggedIn)
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
}
