//
//  QRCode.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/17/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//  Reference: https://janthielemann.de/ios-development/export-cifilter-qr-code-uiimage-uipasteboard-share-ciimage-fly/
//

import UIKit

struct QRCode {
  let text: String

  func generateQRCode() -> UIImage? {
    let textData = text.data(using: .ascii)

    if let filter = CIFilter(name: "CIQRCodeGenerator") {
      filter.setValue(textData, forKey: "inputMessage")
      let transform = CGAffineTransform(scaleX: 10, y: 10)
      guard let ciImage = filter.outputImage else { return nil }
      let scaledCIImage = ciImage.transformed(by: transform)

      //Convert to CGImage: - Enable to share/copy the image
      let ciContext = CIContext()
      if let cgImage = ciContext.createCGImage(scaledCIImage, from: scaledCIImage.extent) {
        return UIImage(cgImage: cgImage)
      }
    }
    return nil
  }
}
