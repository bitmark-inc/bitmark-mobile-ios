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
  var captureSession: AVCaptureSession!
  weak var delegate: QRCodeScannerDelegate!

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "SCAN QRCODE"

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
    let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    videoPreviewLayer.frame = view.layer.bounds
    view.layer.addSublayer(videoPreviewLayer)

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
