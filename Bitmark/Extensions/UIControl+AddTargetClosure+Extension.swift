//
//  UIButton+AddTargetClosure+Extension.swift
//  Bitmark
//
//  Created by Thuyen Truong on 6/10/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//  Reference: https://stackoverflow.com/questions/25919472/adding-a-closure-as-target-to-a-uibutton
//

import UIKit

class ClosureSleeve {
  let closure: () -> Void

  init (_ closure: @escaping () -> Void) {
    self.closure = closure
  }

  @objc func invoke () {
    closure()
  }
}

extension UIControl {

  func addAction(for controlEvents: UIControl.Event, _ closure: @escaping () -> Void) {
    let sleeve = ClosureSleeve(closure)
    addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvents)

    // make the sleeve instance to be retained for the lifetime of the UIControl
    objc_setAssociatedObject(self, "[\(arc4random())]", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
  }
}
