//
//  Constant.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

public struct Constant {

  // MARK: - Confirmation
  public struct Confirmation {
    public static let deleteLabel = "Are you sure you want to delete this label?"
  }

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
      public static let photo = "Please enable access to photos in privacy setting."
    }
  }

  // MARK: - Success Message
  public struct Success {
    public static let issue = "Your property rights have been registerred."
  }

  public struct Message {
    public static let sendingTransaction = "Sending your transaction to the Birmark network..."
  }
}
