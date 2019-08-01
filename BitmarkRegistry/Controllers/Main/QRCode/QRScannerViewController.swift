//
//  QRScannerViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/18/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//  Reference: https://medium.com/appcoda-tutorials/how-to-build-qr-code-scanner-app-in-swift-b5532406dd6b
//

import UIKit
import AVFoundation

protocol QRCodeScannerDelegate: class {
  func process(qrCode: String?)
}

enum QRCodeScanType {
  case accountNumber, chibitronicsCode
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

  // MARK: - Properties
  var qrCodeScanType: QRCodeScanType!
  var verificationLink: String?
  var videoPreviewLayer: AVCaptureVideoPreviewLayer!
  var captureSession: AVCaptureSession!
  weak var delegate: QRCodeScannerDelegate!
  var chibitronicsService: ChibitronicsService!

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "SCAN QR CODE"

    setupViews()
    performRealtimeCapture()

    if let verificationLink = verificationLink {
      captureSession.stopRunning()
      processVerificationLink(verificationLink)
    }
  }

  func performRealtimeCapture() {
    let deviceDiscoverySession  = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)

    guard let captureDevice = deviceDiscoverySession.devices.first else {
      showErrorAlert(message: "Failed to get the camera device")
      return
    }

    captureSession = AVCaptureSession()

    do {
      let input = try AVCaptureDeviceInput(device: captureDevice)
      captureSession.addInput(input)
    } catch {
      showErrorAlert(message: "The device cannot be opened because it is no longer available or because it is in use.")
      return
    }

    let captureMetadataOutput = AVCaptureMetadataOutput()
    captureSession.addOutput(captureMetadataOutput)

    captureMetadataOutput.setMetadataObjectsDelegate(self, queue: .main)
    captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

    // initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
    videoPreviewLayer.session = captureSession

    // start video capture.
    captureSession.startRunning()
  }

  func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    guard !metadataObjects.isEmpty else { return }

    guard let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject else { return }
    if metadataObj.type == AVMetadataObject.ObjectType.qr, let qrCode = metadataObj.stringValue {
      captureSession.stopRunning()

      switch qrCodeScanType! {
      case .accountNumber:
        delegate.process(qrCode: qrCode)
        navigationController?.popViewController(animated: true)
      case .chibitronicsCode:
        processVerificationLink(qrCode)
      }
    }
  }

  @objc func backNavigation(_ sender: UIAlertAction) {
    navigationController?.popViewController(animated: true)
  }
}

// MARK: - processVerificationLink - Chibitronics
extension QRScannerViewController {
  fileprivate func processVerificationLink(_ code: String) {
    let verificationLinkSource: VerificationLinkSource = verificationLink == nil ? .qrCode : .deepLink
    Global.verificationLink = nil
    chibitronicsService = ChibitronicsService(verificationLink: code, source: verificationLinkSource)

    guard chibitronicsService.isValid(),
          let (_, url) = chibitronicsService.extractData(), let urlHost = url.host else {
      let unrecognizedQRCode = Constant.Error.unrecognizedQRCode
      let alertController = UIAlertController(title: unrecognizedQRCode.title, message: unrecognizedQRCode.message, preferredStyle: .alert)
      alertController.addAction(title: "OK", style: .default) { [weak self] (_) in
        self?.captureSession.startRunning()
      }
      present(alertController, animated: true, completion: nil)
      return
    }

    let authorizationRequired = Constant.Confirmation.authorizationRequired
    let message = "\(urlHost) \(authorizationRequired.requiredSignatureMessage)"
    let alertController = UIAlertController(title: authorizationRequired.title, message: message, preferredStyle: .alert)
    alertController.addAction(title: "Cancel", style: .default, handler: backNavigation(_:))
    alertController.addAction(title: "Authorize", style: .default, handler: authorize(_:))
    present(alertController, animated: true, completion: nil)
  }

  @objc func authorize(_ sender: UIAlertAction) {
    guard let urlHost = chibitronicsService.url.host else { return }
    do {
      try chibitronicsService.requestAuthorization(for: Global.currentAccount!) { [weak self] (error) in
        guard let self = self else { return }
        DispatchQueue.main.sync {

          if let error = error {
            ErrorReporting.report(error: error)
            self.showErrorAlert(title: "Error", message: "There was an error while requesting to \(urlHost)")
            return
          }

          self.showQuickMessageAlert(
            title: "Authorized!",
            message: "Your authorization has been sent to \(urlHost).",
            handler: {
              self.navigationController?.popViewController(animated: true)
              self.delegate.process(qrCode: nil)
          })
        }
      }
    } catch {
      ErrorReporting.report(error: error)
      self.showErrorAlert(title: "Error", message: "There was an error while requesting to \(urlHost)")
    }
  }

  fileprivate func showErrorAlert(title: String, message: String) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(title: "OK", style: .default) { (_) in
      self.captureSession.startRunning()
    }
    present(alertController, animated: true, completion: nil)
  }
}

// MARK: - Setup Views
extension QRScannerViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    let descriptionLabelView = CommonUI.descriptionLabel()
    descriptionLabelView.attributedText = setupDescriptionText()

    // initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
    videoPreviewLayer = AVCaptureVideoPreviewLayer()
    videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    videoPreviewLayer.frame = CGRect(x: 0, y: 250, width: view.frame.width, height: view.frame.width)

    view.addSubview(descriptionLabelView)
    view.layer.addSublayer(videoPreviewLayer)

    descriptionLabelView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 0, right: 25))
    }
  }

  fileprivate func setupDescriptionText() -> NSMutableAttributedString {
    guard let qrCodeScanType = qrCodeScanType else { return NSMutableAttributedString(string: "") }
    switch qrCodeScanType {
    case .accountNumber:
      let descriptionText = NSMutableAttributedString(string: "You can transfer rights to another Bitmark account by scanning the receiving account’s QR code. You can view your account QR code by tapping ")

      let qrCodeAttachment = NSTextAttachment()
      qrCodeAttachment.image = UIImage(named: "qr-code-icon")
      qrCodeAttachment.bounds = CGRect(x: 0, y: 0, width: 19, height: 19)

      // add the NSTextAttachment wrapper to our full string, then add some more text.
      descriptionText.append(NSAttributedString(attachment: qrCodeAttachment))
      descriptionText.append(NSAttributedString(string: " at the top of the Account screen."))
      return descriptionText
    case .chibitronicsCode:
      return NSMutableAttributedString(string: "You can accept rights transfers from certain websites by scanning QR codes. Please only scan QR codes from websites that you already know and trust.")
    }
  }
}
