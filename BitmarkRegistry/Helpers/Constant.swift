//
//  Constant.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/31/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

public struct Constant {

  // MARK: - Error Messages
  public struct Error {
    public struct Metadata {
      public static let duplication = "Duplicated labels! "
    }

    public struct NumberOfBitmarks {
      public static let minimumQuantity = "Create property requires a minimum quantity of 1 bitmark issuance."
      public static let maxinumQuantity = "You cannot issue more than 100 birmarks"
    }

    public struct Permission {
      public static let photo = "Please enable access to photos in privacy setting"
    }
  }
}
