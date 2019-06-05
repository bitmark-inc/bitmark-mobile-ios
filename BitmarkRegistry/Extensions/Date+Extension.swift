//
//  Date+Extension.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/5/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

extension Date {
  func format(dateFormat: String = Constant.systemFullFormatDate) -> String {
    let dateFormatterPrint = DateFormatter()
    dateFormatterPrint.dateFormat = dateFormat

    return dateFormatterPrint.string(from: self).uppercased()
  }
}
