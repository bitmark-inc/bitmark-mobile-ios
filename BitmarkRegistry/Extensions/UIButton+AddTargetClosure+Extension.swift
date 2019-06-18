//
//  UIButton+AddTargetClosure+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/10/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//  Reference: https://stackoverflow.com/questions/25919472/adding-a-closure-as-target-to-a-uibutton
//

import UIKit

class ClosureSleeve {
  let closure: ()->()

  init (_ closure: @escaping ()->()) {
    self.closure = closure
  }

  @objc func invoke () {
    closure()
  }
}

extension UIControl {

  func addAction(for controlEvents: UIControl.Event, _ closure: @escaping ()->()) {
    let sleeve = ClosureSleeve(closure)
    addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)

    // make the sleeve instance to be retained for the lifetime of the UIControl
    objc_setAssociatedObject(self, "[\(arc4random())]", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
  }
}
