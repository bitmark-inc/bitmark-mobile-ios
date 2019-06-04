//
//  RegisterPropertyViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/31/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import Photos

class RegisterPropertyViewController: UIViewController {

  // MARK: - Properties
  let registerPropertyRightsSegueIdentifier = "registerPropertyRightsSegue"
  var assetData: UIImage?
  var assetFileName: String?

  // MARK: - Handlers
  // Show actionSheet Alert with option: Choose from Library
  @IBAction func tapPhotosToRegiter(_ sender: UIButton) {
    let alertController = UIAlertController()
    let alertAction = UIAlertAction(title: "Choose from Library...", style: .default, handler: handler)
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alertController.addAction(alertAction)
    alertController.addAction(cancelAction)
    self.present(alertController, animated: true, completion: nil)
  }

  func handler(alert: UIAlertAction) {
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

    // Get File
    guard let image = info[.originalImage] as? UIImage else { return }
    assetData = image

    // Get Filename
    if let asset = info[.phAsset] as? PHAsset,
      let assetResource = PHAssetResource.assetResources(for: asset).first {
      assetFileName = assetResource.originalFilename
    }

    performSegue(withIdentifier: registerPropertyRightsSegueIdentifier, sender: nil)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == registerPropertyRightsSegueIdentifier {
      let destination = segue.destination as! RegisterPropertyRightsViewController
      destination.assetFile = assetData
      destination.assetFileName = assetFileName
    }
  }
}
