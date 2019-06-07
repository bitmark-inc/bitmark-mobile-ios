//
//  QRScannerViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/6/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import AVFoundation

protocol QRCodeScannerDelegate {
  func process(qrCode: String)
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

  var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  var qrCodeFrameView: UIView?
  var captureSession = AVCaptureSession()
  var receivedQRCode: Bool = false

  var delegate: QRCodeScannerDelegate!

  override func viewDidLoad() {
    super.viewDidLoad()

    let deviceDiscoverySession  = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back)
    print(deviceDiscoverySession.devices)

    guard let captureDevice = deviceDiscoverySession.devices.first else { return }

    do {
      let input = try AVCaptureDeviceInput(device: captureDevice)
      captureSession.addInput(input)
    } catch let e {
      showErrorAlert(message: e.localizedDescription)
    }

    let captureMetadataOutput = AVCaptureMetadataOutput()
    captureSession.addOutput(captureMetadataOutput)

    captureMetadataOutput.setMetadataObjectsDelegate(self, queue: .main)
    captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]


    // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
    videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
    videoPreviewLayer?.frame = view.layer.bounds
    view.layer.addSublayer(videoPreviewLayer!)

    // Start video capture.
    captureSession.startRunning()
  }

  func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    guard metadataObjects.count > 0 else { return }

    let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject

    if !receivedQRCode, metadataObj.type == AVMetadataObject.ObjectType.qr, let qrCode = metadataObj.stringValue {
      receivedQRCode = true
      delegate.process(qrCode: qrCode)
      navigationController?.popViewController(animated: true)
    }

  }
}
