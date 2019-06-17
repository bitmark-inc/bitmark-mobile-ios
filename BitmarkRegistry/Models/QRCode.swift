//
//  QRCode.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/17/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

struct QRCode {
  let text: String

  func generateQRCode() -> UIImage? {
    let textData = text.data(using: .ascii)

    if let filter = CIFilter(name: "CIQRCodeGenerator") {
      filter.setValue(textData, forKey: "inputMessage")
      let transform = CGAffineTransform(scaleX: 3, y: 3)

      if let output = filter.outputImage?.transformed(by: transform) {
        return UIImage(ciImage: output)
      }
    }
    return nil
  }
}
