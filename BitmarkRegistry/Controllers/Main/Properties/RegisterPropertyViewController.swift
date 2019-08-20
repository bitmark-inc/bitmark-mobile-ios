//
//  RegisterPropertyViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import Photos
import RxFlow
import RxCocoa

class RegisterPropertyViewController: UIViewController, Stepper {
  var steps = PublishRelay<Step>()

  // MARK: - Properties
  var assetFileName: String?
  var assetURL: URL?

  var registerByPhotoButton: UIButton!
  var registerByFileButton: UIButton!
  var descriptionLabel: UILabel!
  var browserFileAlertController: UIAlertController!
  var disabledScreen: UIView!
  var activityIndicator: UIActivityIndicatorView!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "REGISTER"
    navigationItem.backBarButtonItem = UIBarButtonItem()
    setupViews()
    setupEvents()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    enableScreen()
  }

  deinit {
    disabledScreen.removeFromSuperview()
  }

  // MARK: - Handlers
  // Show actionSheet Alert with option: Choose from Library
  @objc func tapPhotosToRegiter(_ sender: UIButton) {
    let alertController = UIAlertController()
    alertController.addAction(title: "registerProperty_chooseFromLibrary".localized(tableName: "Phrase"), handler: imagePickerHandler)
    alertController.addAction(title: "Cancel".localized(), style: .cancel)
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
    browserFileAlertController.addAction(title: "Cancel".localized(), style: .cancel)

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
    activityIndicator.startAnimating()
    disabledScreen.isHidden = false

    picker.dismiss(animated: true) { [weak self] in
      guard let self = self, let assetURL = info[.imageURL] as? URL else { return }
      self.assetURL = assetURL

      // get image name
      if let asset = info[.phAsset] as? PHAsset,
        let assetResource = PHAssetResource.assetResources(for: asset).first {
        self.assetFileName = assetResource.originalFilename
      }

      self.performMoveToRegisterPropertyRights()
    }
  }

  fileprivate func performMoveToRegisterPropertyRights() {
    guard let assetURL = self.assetURL, let assetFileName = assetFileName else { return }
    guard isFileSizeValid(assetURL) else {
      showErrorAlert(message: "This asset size is too large. The maximum asset size is 100MB.")
      enableScreen()
      return
    }

    steps.accept(BitmarkStep.createPropertyRights(assetURL: assetURL, assetFilename: assetFileName))
  }

  fileprivate func isFileSizeValid(_ assetURL: URL) -> Bool {
    do {
      let fileAttributes = try FileManager.default.attributesOfItem(atPath: assetURL.path)
      guard let fileSizeinB = fileAttributes[FileAttributeKey.size] as? NSNumber else { return false }
      return (fileSizeinB.uint64Value / 1024 / 1024) <= 100 // limit 100MB
    } catch {
      ErrorReporting.report(error: error)
      return false
    }
  }
}

// MARK: - UIDocumentPickerDelegate
extension RegisterPropertyViewController: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
    activityIndicator.startAnimating()
    disabledScreen.isHidden = false

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      let didStartAccessing = url.startAccessingSecurityScopedResource()
      defer {
        if didStartAccessing {
          url.stopAccessingSecurityScopedResource()
        }
      }

      let fileCoordinator = NSFileCoordinator()
      var error: NSError?
      fileCoordinator.coordinate(readingItemAt: url, options: [], error: &error) { (newURL) in
        self.assetFileName = newURL.lastPathComponent
        self.assetURL = newURL
        self.performMoveToRegisterPropertyRights()
      }
    }
  }

  fileprivate func enableScreen() {
    activityIndicator.stopAnimating()
    disabledScreen.isHidden = true
  }
}

// MARK: - Setup Views/Events
extension RegisterPropertyViewController {
  fileprivate func setupEvents() {
    registerByPhotoButton.addTarget(self, action: #selector(tapPhotosToRegiter), for: .touchUpInside)
    registerByFileButton.addTarget(self, action: #selector(tapFilesToRegister), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    registerByPhotoButton = registerButton(by: "PHOTO OR VIDEO", imageName: "image-picker")
    registerByFileButton = registerButton(by: "File".localized().localizedUppercase, imageName: "file-picker")

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

    descriptionLabel = CommonUI.descriptionLabel(text: "registerProperty_message".localized(tableName: "Phrase"))
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

    setupDisabledScreen()
  }

  fileprivate func registerButton(by text: String, imageName: String) -> UIButton {
    let button = UIButton(type: .system)
    button.backgroundColor = .aliceBlue
    button.setTitle(text, for: .normal)
    button.setTitleColor(.mainBlueColor, for: .normal)
    button.titleLabel?.font = UIFont(name: "Avenir-Black", size: 16)
    button.contentHorizontalAlignment = .left
    button.titleEdgeInsets.left = 80
    button.snp.makeConstraints { $0.height.equalTo(45) }

    let imageView = UIImageView(image: UIImage(named: imageName))
    let prefixView = UIView()
    prefixView.addSubview(imageView)
    imageView.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
    }

    let nextArrowImageView = UIImageView(image: UIImage(named: "next-arrow"))
    nextArrowImageView.contentMode = .scaleAspectFit

    button.addSubview(prefixView)
    button.addSubview(nextArrowImageView)

    prefixView.snp.makeConstraints { (make) in
      make.centerY.leading.equalToSuperview()
      make.width.equalTo(70)
    }

    nextArrowImageView.snp.makeConstraints { (make) in
      make.centerY.equalToSuperview()
      make.trailing.equalToSuperview().offset(-20)
    }

    return button
  }

  fileprivate func setupBrowserActionButton() -> UIButton {
    let browserTextLabel = UILabel(text: "Browse")
    browserTextLabel.font = UIFont(name: "Arial", size: 16)
    let browserImage = UIImage(named: "browser-icon")

    let browserButton = UIButton()
    browserButton.frame = CGRect(x: 0, y: 16, width: view.frame.width - 35, height: 25)
    browserButton.contentHorizontalAlignment = .leading
    browserButton.setTitle("Browse", for: .normal)
    browserButton.setTitleColor(.black, for: .normal)
    browserButton.setImage(browserImage, for: .normal)
    browserButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: browserButton.frame.width - 20, bottom: 0, right: 0)

    return browserButton
  }

  fileprivate func setupDisabledScreen() {
    disabledScreen = CommonUI.disabledScreen()
    activityIndicator = CommonUI.appActivityIndicator()

    guard let currentWindow: UIWindow = UIApplication.shared.keyWindow else { return }
    currentWindow.addSubview(disabledScreen)
    disabledScreen.addSubview(activityIndicator)
    disabledScreen.isHidden = true

    disabledScreen.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }

    activityIndicator.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
    }
  }
}
