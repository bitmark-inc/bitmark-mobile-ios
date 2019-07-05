//
//  RegisterPropertyViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import Photos

class RegisterPropertyViewController: UIViewController {

  // MARK: - Properties
  var assetData: Data?
  var assetFileName: String?
  var assetURL: URL?

  var registerByPhotoButton: UIButton!
  var registerByFileButton: UIButton!
  var descriptionLabel: UILabel!
  var browserFileAlertController: UIAlertController!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "REGISTER"
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
    setupEvents()
  }

  // MARK: - Handlers
  // Show actionSheet Alert with option: Choose from Library
  @objc func tapPhotosToRegiter(_ sender: UIButton) {
    let alertController = UIAlertController()
    alertController.addAction(title: "Choose from Library...", handler: imagePickerHandler)
    alertController.addAction(title: "Cancel", style: .cancel)
    present(alertController, animated: true, completion: nil)
  }

  @objc func tapFilesToRegister(_ sender: UIButton) {
    let browserAction = UIAlertAction(title: "", style: .default) { [weak self] in
      self?.documentPickerHandler($0)
    }
    let browserButton = setupBrowserActionButton()
    browserButton.addTarget(self, action: #selector(documentPickerHandler), for: .touchUpInside)

    browserFileAlertController = UIAlertController()
    browserFileAlertController.view.addSubview(browserButton)
    browserFileAlertController.addAction(browserAction)
    browserFileAlertController.addAction(title: "Cancel", style: .cancel)

    present(browserFileAlertController, animated: true, completion: nil)
  }

  @objc func imagePickerHandler(_ sender: UIAlertAction) {
    askForPhotosPermission { [unowned self] (status) in
      if status == .authorized {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = false
        imagePickerController.sourceType = .photoLibrary
        self.present(imagePickerController, animated: true, completion: nil)
      } else {
        self.showErrorAlert(message: Constant.Error.Permission.photo)
      }
    }
  }

  @objc func documentPickerHandler(_ sender: Any) {
    browserFileAlertController?.dismiss(animated: false, completion: nil)
    let documentPickerController = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
    documentPickerController.delegate = self
    present(documentPickerController, animated: true, completion: nil)
  }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension RegisterPropertyViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    picker.dismiss(animated: true, completion: nil)

    // get image
    guard let image = info[.originalImage] as? UIImage else { return }
    assetData = image.pngData()

    // get image name
    if let asset = info[.phAsset] as? PHAsset,
      let assetResource = PHAssetResource.assetResources(for: asset).first {
      assetFileName = assetResource.originalFilename
    }

    assetURL = info[.imageURL] as? URL

    performMoveToRegisterPropertyRights()
  }

  fileprivate func performMoveToRegisterPropertyRights() {
    let registerPropertyRightsVC = RegisterPropertyRightsViewController()
    registerPropertyRightsVC.hidesBottomBarWhenPushed = true
    registerPropertyRightsVC.assetData = assetData
    registerPropertyRightsVC.assetFileName = assetFileName
    registerPropertyRightsVC.assetURL = assetURL
    navigationController?.pushViewController(registerPropertyRightsVC)
  }
}

// MARK: - UIDocumentPickerDelegate
extension RegisterPropertyViewController: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
    let didStartAccessing = url.startAccessingSecurityScopedResource()
    defer {
      if didStartAccessing {
        url.stopAccessingSecurityScopedResource()
      }
    }

    let fileCoordinator = NSFileCoordinator()
    var error: NSError?
    fileCoordinator.coordinate(readingItemAt: url, options: [], error: &error) { (newURL) in
      do {
        assetData = try Data(contentsOf: newURL)
      } catch {
        showErrorAlert(message: Constant.Error.accessFile)
        return
      }
      assetFileName = newURL.lastPathComponent
      assetURL = newURL
      performMoveToRegisterPropertyRights()
    }
  }
}

// MARK: - Setup Views/Events
extension RegisterPropertyViewController {
  private func setupEvents() {
    registerByPhotoButton.addTarget(self, action: #selector(tapPhotosToRegiter), for: .touchUpInside)
    registerByFileButton.addTarget(self, action: #selector(tapFilesToRegister), for: .touchUpInside)
  }

  private func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    registerByPhotoButton = registerButton(by: "PHOTOS")
    registerByFileButton = registerButton(by: "FILES")

    let registerSelectionView = UIStackView(
      arrangedSubviews: [registerByPhotoButton, registerByFileButton],
      axis: .vertical,
      spacing: 10.0,
      alignment: .leading,
      distribution: .fill
    )
    registerSelectionView.arrangedSubviews.forEach({
      $0.snp.makeConstraints { $0.width.equalToSuperview() }
    })

    descriptionLabel = CommonUI.descriptionLabel(text: "Property rights are registered on Bitmark through the creation of an asset record followed by an issue record." +
      " Once an asset has been issued, transferring it simply requires taking advantage of the blockchain's standard attributes.")
    descriptionLabel.lineHeightMultiple(1.2)

    // *** Setup UI in view ***
    view.addSubview(registerSelectionView)
    view.addSubview(descriptionLabel)

    registerSelectionView.snp.makeConstraints { (make) in
      make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
      make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
    }

    descriptionLabel.snp.makeConstraints { (make) in
      make.top.equalTo(registerSelectionView.snp.bottom).offset(18)
      make.leading.equalTo(view.safeAreaLayoutGuide).offset(20)
      make.trailing.equalTo(view.safeAreaLayoutGuide).offset(-20)
    }
  }

  private func registerButton(by text: String) -> UIButton {
    let button = UIButton()
    button.backgroundColor = .aliceBlue
    button.setTitle(text, for: .normal)
    button.setTitleColor(.mainBlueColor, for: .normal)
    button.titleLabel?.font = UIFont(name: "Avenir-Black", size: 16)
    button.contentHorizontalAlignment = .left
    button.titleEdgeInsets.left = 20.0
    button.snp.makeConstraints { $0.height.equalTo(45) }
    return button
  }

  fileprivate func setupBrowserActionButton() -> UIButton {
    let browserTextLabel = UILabel(text: "Browser")
    browserTextLabel.font = UIFont(name: "Arial", size: 16)
    let browserImage = UIImage(named: "browser-icon")

    let browserButton = UIButton()
    browserButton.frame = CGRect(x: 0, y: 16, width: view.frame.width - 35, height: 25)
    browserButton.contentHorizontalAlignment = .leading
    browserButton.setTitle("Browser", for: .normal)
    browserButton.setTitleColor(.black, for: .normal)
    browserButton.setImage(browserImage, for: .normal)
    browserButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: browserButton.frame.width - 20, bottom: 0, right: 0)

    return browserButton
  }
}
