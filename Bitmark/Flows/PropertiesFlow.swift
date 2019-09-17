//
//  PropertiesFlow.swift
//  Bitmark
//
//  Created by Thuyen Truong on 8/19/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import Foundation
import RxFlow
import RxCocoa
import Alamofire

class PropertiesFlow: Flow {
  var root: Presentable {
    return self.rootViewController
  }
  private lazy var rootViewController: UINavigationController = {
    let navigationController = UINavigationController()
    navigationController.navigationBar.shadowImage = UIImage()
    navigationController.navigationBar.titleTextAttributes = [.font: UIFont(name: "Avenir-Black", size: 18)!]
    return navigationController
  }()

  private let networkReachabilityManager = NetworkReachabilityManager()

  func navigate(to step: Step) -> FlowContributors {
    guard let step = step as? BitmarkStep else { return .none }

    switch step {
    case .listOfProperties:
      return navigateToPropertiesScreen()
    case .createProperty:
      guard let networkReachabilityManager = networkReachabilityManager, networkReachabilityManager.isReachable else {
        Global.showNoInternetBanner()
        return .none
      }
      return navigateToCreatePropertyScreen()
    case .createPropertyRights(let assetURL, let assetFilename):
      return navigateToCreatePropertyRightsScreen(assetURL: assetURL, assetFilename: assetFilename)
    case .endCreatePropertyRights:
      rootViewController.popViewController(animated: true)
      return .none
    case .viewPropertyDescriptionInfo:
      return navigateToViewPropertyDescriptionInfoScreen()
    case .viewTransferBitmark(let bitmarkId, let assetR):
      return navigateToTransferBitmarkScreen(bitmarkId: bitmarkId, assetR: assetR)
    case .issueIsComplete, .transferBitmarkIsComplete, .deleteBitmarkIsComplete:
      rootViewController.popToRootViewController(animated: true)
      return .none
    case .scanOwnershipCode:
      return navigateToScanOwnershipCodeScreen()
    case .viewBitmarkDetails(let bitmarkR, let assetR):
      return navigateToBitmarkDetails(bitmarkR: bitmarkR, assetR: assetR)
    case .viewRegistryAccountDetails(let accountNumber):
      return navigateToRegistryAccountDetailsScreen(accountNumber: accountNumber)
    case .viewMusicBitmarkDetails(let bitmarkR, let assetR):
      return navigateToMusicBitmarkDetails(bitmarkR: bitmarkR, assetR: assetR)
    case .viewMusicBitmarkDetailsIsComplete:
      rootViewController.isNavigationBarHidden = false
      rootViewController.popViewController(animated: true)
      return .none
    case .viewRegistryBitmarkDetails(let bitmarkId):
      return navigateToRegistryBitmarkDetailsScreen(bitmarkId: bitmarkId)
    default:
      return .none
    }
  }

  private func navigateToPropertiesScreen() -> FlowContributors {
    let viewController = PropertiesViewController()
    self.rootViewController.pushViewController(viewController, animated: true)

    if let navigationItem = self.rootViewController.navigationBar.items?[0] {
      let ownershipScanButton = UIBarButtonItem(image: UIImage(named: "qr-code-scan-icon"), style: .plain, target: viewController, action: #selector(viewController.tapToScanOwnershipCode))
      let addBarButton = UIBarButtonItem(image: UIImage(named: "add-plus"), style: .plain, target: viewController, action: #selector(viewController.tapToAddProperty))
      navigationItem.title = "Properties".localized().localizedUppercase
      navigationItem.rightBarButtonItem = addBarButton
      navigationItem.leftBarButtonItem = ownershipScanButton
      navigationItem.backBarButtonItem = UIBarButtonItem()
    }

    return .one(flowContributor: .contribute(withNextPresentable: viewController, withNextStepper: viewController))
  }

  fileprivate func navigateToCreatePropertyScreen() -> FlowContributors {
    let registerPropertyVC = RegisterPropertyViewController()
    self.rootViewController.pushViewController(registerPropertyVC, animated: true)
    return .one(flowContributor: .contribute(withNextPresentable: registerPropertyVC, withNextStepper: registerPropertyVC))
  }

  fileprivate func navigateToCreatePropertyRightsScreen(assetURL: URL, assetFilename: String) -> FlowContributors {
    let registerPropertyRightsVC = RegisterPropertyRightsViewController()
    registerPropertyRightsVC.hidesBottomBarWhenPushed = true
    registerPropertyRightsVC.assetFileName = assetFilename
    registerPropertyRightsVC.assetURL = assetURL
    self.rootViewController.pushViewController(registerPropertyRightsVC, animated: true)
    return .one(flowContributor: .contribute(withNextPresentable: registerPropertyRightsVC, withNextStepper: registerPropertyRightsVC))
  }

  fileprivate func navigateToViewPropertyDescriptionInfoScreen() -> FlowContributors {
    let infoVC = PropertyDescriptionInfoViewController()
    self.rootViewController.pushViewController(infoVC, animated: true)
    return .none
  }

  fileprivate func navigateToTransferBitmarkScreen(bitmarkId: String, assetR: AssetR) -> FlowContributors {
    let transferBitmarkVC = TransferBitmarkViewController()
    transferBitmarkVC.assetR = assetR
    transferBitmarkVC.bitmarkId = bitmarkId
    self.rootViewController.pushViewController(transferBitmarkVC)

    return .one(flowContributor: .contribute(withNextPresentable: transferBitmarkVC, withNextStepper: transferBitmarkVC))
  }

  fileprivate func navigateToScanOwnershipCodeScreen() -> FlowContributors {
    let qrScannerVC = QRScannerViewController()
    qrScannerVC.qrCodeScanType = .ownershipCode
    qrScannerVC.verificationLink = Global.verificationLink

    qrScannerVC.hidesBottomBarWhenPushed = true
    self.rootViewController.pushViewController(qrScannerVC)

    return .one(flowContributor: .contribute(withNextPresentable: qrScannerVC, withNextStepper: qrScannerVC))
  }

  fileprivate func navigateToBitmarkDetails(bitmarkR: BitmarkR, assetR: AssetR) -> FlowContributors {
    let bitmarkDetailsVC = BitmarkDetailViewController()
    bitmarkDetailsVC.bitmarkR = bitmarkR
    bitmarkDetailsVC.assetR = assetR

    bitmarkDetailsVC.hidesBottomBarWhenPushed = true
    rootViewController.pushViewController(bitmarkDetailsVC)

    return .one(flowContributor: .contribute(withNextPresentable: bitmarkDetailsVC, withNextStepper: bitmarkDetailsVC))
  }

  fileprivate func navigateToRegistryAccountDetailsScreen(accountNumber: String) -> FlowContributors {
    let registryDetailVC = RegistryDetailViewController()
    registryDetailVC.query = "/account/" + accountNumber
    self.rootViewController.pushViewController(registryDetailVC)
    return .none
  }

  fileprivate func navigateToMusicBitmarkDetails(bitmarkR: BitmarkR, assetR: AssetR) -> FlowContributors {
    let musicBitmarkDetailsVC = MusicBitmarkDetailViewController()
    musicBitmarkDetailsVC.bitmarkR = bitmarkR
    musicBitmarkDetailsVC.assetR = assetR

    musicBitmarkDetailsVC.hidesBottomBarWhenPushed = true
    rootViewController.pushViewController(musicBitmarkDetailsVC)
    rootViewController.isNavigationBarHidden = true

    return .one(flowContributor: .contribute(withNextPresentable: musicBitmarkDetailsVC, withNextStepper: musicBitmarkDetailsVC))
  }

  fileprivate func navigateToRegistryBitmarkDetailsScreen(bitmarkId: String) -> FlowContributors {
    let registryDetailVC = RegistryDetailViewController()
    registryDetailVC.query = "/bitmark/" + bitmarkId
    self.rootViewController.pushViewController(registryDetailVC)
    return .none
  }
}

class PropertiesStepper: Stepper {
  static let shared = PropertiesStepper()
  let steps = PublishRelay<Step>()

  var initialStep: Step {
    return BitmarkStep.listOfProperties
  }

  func goToBitmarkDetailsScreen(bitmarkR: BitmarkR, assetR: AssetR) {
    steps.accept(BitmarkStep.viewBitmarkDetails(bitmarkR: bitmarkR, assetR: assetR))
  }
}
