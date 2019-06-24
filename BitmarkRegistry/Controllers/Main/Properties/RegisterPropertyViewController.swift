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
  var assetFile: UIImage?
  var assetFileName: String?

  var registerByPhotoButton: UIButton!
  var registerByFileButton: UIButton!
  var descriptionLabel: UILabel!

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
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension RegisterPropertyViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true, completion: nil)

    // get image
    guard let image = info[.originalImage] as? UIImage else { return }
    assetFile = image

    // get image name
    if let asset = info[.phAsset] as? PHAsset,
      let assetResource = PHAssetResource.assetResources(for: asset).first {
      assetFileName = assetResource.originalFilename
    }

    performMoveToRegisterPropertyRights()
  }

  fileprivate func performMoveToRegisterPropertyRights() {
    let registerPropertyRightsVC = RegisterPropertyRightsViewController()
    registerPropertyRightsVC.hidesBottomBarWhenPushed = true
    registerPropertyRightsVC.assetFile = assetFile
    registerPropertyRightsVC.assetFileName = assetFileName
    navigationController?.pushViewController(registerPropertyRightsVC)
  }
}

// MARK: - Setup Views/Events
extension RegisterPropertyViewController {
  private func setupEvents() {
    registerByPhotoButton.addTarget(self, action: #selector(tapPhotosToRegiter), for: .touchUpInside)
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
    registerSelectionView.arrangedSubviews.forEach {
      $0.snp.makeConstraints( { $0.width.equalToSuperview() })
    }

    descriptionLabel = CommonUI.descriptionLabel(text: "Property rights are registered on Bitmark through the creation of an asset record followed by an issue record. Once an asset has been issued, transferring it simply requires taking advantage of the blockchain's standard attributes.")
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

  private func registerButton(by text: String) -> UIButton{
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
}
