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
import RxSwift
import RxFlow
import RxCocoa

protocol QRCodeScannerDelegate: class {
  func process(qrCode: String?)
}

enum QRCodeScanType {
  case accountNumber, ownershipCode
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, Stepper {
  var steps = PublishRelay<Step>()

  // MARK: - Properties
  var qrCodeScanType: QRCodeScanType!
  var verificationLink: String?
  var videoPreviewLayer: AVCaptureVideoPreviewLayer!
  var captureSession: AVCaptureSession!
  weak var delegate: QRCodeScannerDelegate!
  var ownershipService: OwnershipApprovanceService!

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "ScanQRCode".localized().localizedUppercase

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
      showErrorAlert(message: "noCamera".localized(tableName: "Error"))
      return
    }

    captureSession = AVCaptureSession()

    do {
      let input = try AVCaptureDeviceInput(device: captureDevice)
      captureSession.addInput(input)
    } catch {
      showErrorAlert(message: "noCamera".localized(tableName: "Error"))
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
      case .ownershipCode:
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
    ownershipService = OwnershipApprovanceService(verificationLink: code, source: verificationLinkSource)

    guard ownershipService.isValid(),
          let (_, url) = ownershipService.extractData(), let urlHost = url.host else {
      let alertController = UIAlertController(
        title: "unrecognizedQRCode_title".localized(tableName: "Error"),
        message: "unrecognizedQRCode_message".localized(tableName: "Error"),
        preferredStyle: .alert
      )
      alertController.addAction(title: "OK".localized(), style: .default) { [weak self] (_) in
        self?.captureSession.startRunning()
      }
      present(alertController, animated: true, completion: nil)
      return
    }

    let message = urlHost + "authorizationRequired_message".localized(tableName: "Phrase")
    let alertController = UIAlertController(
      title: "authorizationRequired_title".localized(tableName: "Phrase"), message: message, preferredStyle: .alert)
    alertController.addAction(title: "Cancel".localized(), style: .default, handler: backNavigation(_:))
    alertController.addAction(title: "Authorize".localized(), style: .default, handler: authorize(_:))
    present(alertController, animated: true, completion: nil)
  }

  @objc func authorize(_ sender: UIAlertAction) {
    guard let urlHost = ownershipService.url.host else { return }
    do {
      try ownershipService.requestAuthorization(for: Global.currentAccount!) { [weak self] (error) in
        guard let self = self else { return }
        DispatchQueue.main.sync {

          if let error = error {
            ErrorReporting.report(error: error)
            self.showErrorAlert(
              title: "Error".localized(),
              message: String(format: "ownershipClaim_errorRequest".localized(tableName: "Error"), urlHost)
            )
            return
          }

          self.showQuickMessageAlert(
            title: "Authorized!".localized(),
            message: String(format: "ownershipClaim_sendAuthorization".localized(tableName: "Message"), urlHost)
          ) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
            self?.delegate.process(qrCode: nil)
          }
        }
      }
    } catch {
      ErrorReporting.report(error: error)
      self.showErrorAlert(
        title: "Error".localized(),
        message: String(format: "ownershipClaim_errorRequest".localized(tableName: "Error"), urlHost)
      )
    }
  }

  fileprivate func showErrorAlert(title: String, message: String) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alertController.addAction(title: "OK".localized(), style: .default) { (_) in
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
    videoPreviewLayer.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.width)

    let videoPreviewLayerCover = UIView()
    videoPreviewLayerCover.layer.addSublayer(videoPreviewLayer)

    view.addSubview(descriptionLabelView)
    view.addSubview(videoPreviewLayerCover)

    descriptionLabelView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 0, right: 25))
    }

    videoPreviewLayerCover.snp.makeConstraints { (make) in
      make.top.equalTo(descriptionLabelView.snp.bottom).offset(25)
      make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
    }
  }

  fileprivate func setupDescriptionText() -> NSMutableAttributedString {
    guard let qrCodeScanType = qrCodeScanType else { return NSMutableAttributedString(string: "") }
    switch qrCodeScanType {
    case .accountNumber:
      let descriptionText = NSMutableAttributedString(string: "scanQRCode_accountNumber_description_part1".localized(tableName: "Phrase"))

      let qrCodeAttachment = NSTextAttachment()
      qrCodeAttachment.image = UIImage(named: "qr-code-icon")
      qrCodeAttachment.bounds = CGRect(x: 0, y: 0, width: 19, height: 19)

      // add the NSTextAttachment wrapper to our full string, then add some more text.
      descriptionText.append(NSAttributedString(attachment: qrCodeAttachment))
      descriptionText.append(NSAttributedString(string: "scanQRCode_accountNumber_description_part2".localized(tableName: "Phrase")))
      return descriptionText
    case .ownershipCode:
      return NSMutableAttributedString(string: "scanQRCode_rightTransfer_description".localized(tableName: "Phrase"))
    }
  }
}
