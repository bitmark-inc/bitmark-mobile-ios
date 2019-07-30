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
  func process(qrCode: String)
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

  // MARK: - Properties
  var videoPreviewLayer: AVCaptureVideoPreviewLayer!
  var captureSession: AVCaptureSession!
  weak var delegate: QRCodeScannerDelegate!

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "SCAN QRCODE"

    setupViews()

    performRealtimeCapture()
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
      delegate.process(qrCode: qrCode)
      navigationController?.popViewController(animated: true)
    }
  }
}

// MARK: - Setup Views
extension QRScannerViewController {
  fileprivate func setupViews() {
    view.backgroundColor = .white

    let descriptionLabelView = CommonUI.descriptionLabel()
    let descriptionText = NSMutableAttributedString(string: "You can transfer rights to another Bitmark account by scanning the receiving account’s QR code. You can view your account QR code by tapping ")

    let qrCodeAttachment = NSTextAttachment()
    qrCodeAttachment.image = UIImage(named: "qr-code-icon")
    qrCodeAttachment.bounds = CGRect(x: 0, y: 0, width: 19, height: 19)

    // add the NSTextAttachment wrapper to our full string, then add some more text.
    descriptionText.append(NSAttributedString(attachment: qrCodeAttachment))
    descriptionText.append(NSAttributedString(string: " at the top of the Account screen."))

    // draw the result in a label
    descriptionLabelView.attributedText = descriptionText

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
}
