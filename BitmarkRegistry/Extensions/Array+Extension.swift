//
//  Array+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/20/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation
import BitmarkSDK

extension Array where Iterator.Element == Bitmark {
  func firstIndexWithId(_ id: String) -> Int? {
    return self.firstIndex(where: { $0.id == id })
  }

  // Returns unique asc-offset bitmarks
  mutating func removeObsoleteBitmarks() {
    let descBitmarks = self.sorted(by: { $0.offset > $1.offset })
    self = descBitmarks.reduce(into: [Bitmark](), { (bitmarks, bitmark) in
      if bitmarks.firstIndexWithId(bitmark.id) == nil {
        bitmarks.prepend(bitmark)
      }
    })
  }
}
