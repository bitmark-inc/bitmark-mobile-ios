//
//  CustomReceiverQRView.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/7/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class CustomReceiverQRView: UIView {

  let kCONTENT_XIB_NAME = "CustomReceiverQRView"

  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var qrImage: UIImageView!

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    commonInit()

  }

  func commonInit() {
    Bundle.main.loadNibNamed(kCONTENT_XIB_NAME, owner: self, options: nil)
    contentView.fixInView(self)
  }
}

extension UIView {
  func fixInView(_ container: UIView) {
    translatesAutoresizingMaskIntoConstraints = false
    frame = container.frame
    container.addSubview(self)
    leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
    trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
    topAnchor.constraint(equalTo: container.topAnchor).isActive = true
    bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
  }
}
