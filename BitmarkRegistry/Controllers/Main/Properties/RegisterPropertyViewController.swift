//
//  RegisterPropertyViewController.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 6/11/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
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
  var registerByVideoButton: UIButton!
  var registerByFileButton: UIButton!
  var descriptionLabel: UILabel!
  var browserFileAlertController: UIAlertController!
  var disabledScreen: UIView!
  var activityIndicator: UIActivityIndicatorView!
  var selectedMediaTypes: [String] = []

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "Register".localized().localizedUppercase
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
  @objc func tapPhotosToRegiter(_ sender: UIButton) {
    tapLibraryToRegister(mediaTypes: ["public.image"])
  }

  @objc func tapVideoToRegister(_ sender: UIButton) {
    tapLibraryToRegister(mediaTypes: ["public.movie"])
  }

  fileprivate func tapLibraryToRegister(mediaTypes: [String]) {
    askForPhotosPermission { [unowned self] (status) in
      guard status == .authorized else { return }
      self.selectedMediaTypes = mediaTypes

      let imagePickerController = UIImagePickerController()
      imagePickerController.delegate = self
      imagePickerController.allowsEditing = false
      imagePickerController.sourceType = .photoLibrary
      imagePickerController.mediaTypes = mediaTypes
      self.present(imagePickerController, animated: true, completion: nil)
    }
  }

  @objc func tapFilesToRegister(_ sender: UIButton) {
    let documentPickerController = UIDocumentPickerViewController(documentTypes: ["public.item"], in: .import)
    documentPickerController.delegate = self
    present(documentPickerController, animated: true, completion: nil)
  }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension RegisterPropertyViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
    guard selectedMediaTypes.isNotEmpty else { return }
    let photoLibraryTitle = selectedMediaTypes.contains("public.image")
                                ? "Photos".localized()
                                : "Videos".localized()
    viewController.navigationItem.title = photoLibraryTitle
  }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    activityIndicator.startAnimating()
    disabledScreen.isHidden = false
    selectedMediaTypes = []

    picker.dismiss(animated: true) { [weak self] in
      guard let self = self, let assetURL = (info[.mediaURL] ?? info[.imageURL]) as? URL else { return }
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
      showErrorAlert(message: "fileSizeTooLarge".localized(tableName: "Error"))
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
        let filename = newURL.lastPathComponent
        self.assetFileName = filename

        // Fix bug "UIDocumentPickerViewController returns url to a file that does not exist"
        // Reference: https://stackoverflow.com/questions/37109130/uidocumentpickerviewcontroller-returns-url-to-a-file-that-does-not-exist/48007752
        var tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        tempURL.appendPathComponent(filename)

        do {
          if FileManager.default.fileExists(atPath: tempURL.path) {
            try FileManager.default.removeItem(at: tempURL)
          }

          try FileManager.default.moveItem(at: url, to: tempURL)
          self.assetURL = tempURL
        } catch {
          ErrorReporting.report(error: error)
        }

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
    registerByVideoButton.addTarget(self, action: #selector(tapVideoToRegister), for: .touchUpInside)
    registerByFileButton.addTarget(self, action: #selector(tapFilesToRegister), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    registerByPhotoButton = registerButton(by: "Photo".localized().localizedUppercase, imageName: "image-picker")
    registerByVideoButton = registerButton(by: "Video".localized().localizedUppercase, imageName: "video-picker")
    registerByFileButton = registerButton(by: "File".localized().localizedUppercase, imageName: "file-picker")

    let registerSelectionView = UIStackView(
      arrangedSubviews: [
        registerByPhotoButton, registerByVideoButton, registerByFileButton
      ],
      axis: .vertical,
      spacing: 10.0,
      alignment: .leading,
      distribution: .fill
    )
    registerSelectionView.arrangedSubviews.forEach({
      $0.snp.makeConstraints { $0.width.equalToSuperview() }
    })

    // *** Setup UI in view ***
    view.addSubview(registerSelectionView)

    registerSelectionView.snp.makeConstraints { (make) in
      make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
      make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
    }

    setupDisabledScreen()
  }

  fileprivate func registerButton(by text: String, imageName: String) -> UIButton {
    let button = UIButton(type: .system)
    button.backgroundColor = .wildSand
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
