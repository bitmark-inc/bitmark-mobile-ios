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

class AppNavigationViewController: UIViewController {

  // MARK: - Properties
  let disposeBag = DisposeBag()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    setupViews()
    navigate()
  }

  // MARK: - Handlers
  // Redirect Screen for new user / existing user
  func navigate() {
    AccountService.shared.existsCurrentAccount()
      .observeOn(MainScheduler.instance)
      .subscribe(
        onSuccess: { (isAccountExisted) in
          let initialVC: UIViewController
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
            initialVC = CustomTabBarViewController()
          } else {
            let navigationController = UINavigationController(rootViewController: OnboardingViewController())
            navigationController.isNavigationBarHidden = true
            initialVC = navigationController
          }

          UIApplication.shared.keyWindow?.rootViewController = initialVC
        },
        onError: { [weak self] (error) in
          guard let self = self else { return }
          let retryAuthenticationAlert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
          retryAuthenticationAlert.addAction(title: "Retry", style: .default, handler: { [weak self] _ in self?.navigate() })
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

    let imageView = UIImageView(image: UIImage(named: "slogan"))
    imageView.contentMode = .scaleAspectFit
    view.addSubview(imageView)

    imageView.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
      make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
    }
  }
}
