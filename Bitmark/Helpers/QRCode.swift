//
//  QRCode.swift
//  Bitmark
//
//  Created by Thuyen Truong on 6/17/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//  Reference: https://janthielemann.de/ios-development/export-cifilter-qr-code-uiimage-uipasteboard-share-ciimage-fly/
//

import UIKit

struct QRCode {
  let text: String

  func generateQRCode() -> UIImage? {
    let textData = text.data(using: .ascii)

    guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
    filter.setValue(textData, forKey: "inputMessage")
    guard let ciImage = filter.outputImage else { return nil }

    let transform = CGAffineTransform(scaleX: 10, y: 10)
    let scaledCIImage = ciImage.transformed(by: transform)

    // convert to CGImage: - Enable to share/copy the image
    let ciContext = CIContext()
    if let cgImage = ciContext.createCGImage(scaledCIImage, from: scaledCIImage.extent) {
      return UIImage(cgImage: cgImage)
    }
    return nil
  }
}
