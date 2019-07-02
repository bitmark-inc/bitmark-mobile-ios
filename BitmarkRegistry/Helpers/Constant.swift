//
//  Constant.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

public struct Constant {

  public static let systemFullFormatDate = "yyyy MMM dd HH:MM:SS"

  // MARK: - Confirmation
  public struct Confirmation {
    public static let deleteLabel = "Are you sure you want to delete this label?"
    public static let skipTouchFaceIdAuthentication = "Are you sure you don't want to protect your data with Touch & Face ID?"
  }

  // MARK: - Error Messages
  public struct Error {
    public static let createAccount = "There was a problem to create your account."
    public static let keychainStore = "There was a problem saving data in a safe place."
    public static let removeAccess = "There was a problem from removing the access."
    public static let accessFile = "There was a problem to access your selected file."
    public static let syncBitmark = "There was a problem to sync your lastest bitmarks."

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

  public struct Key {
    public static let apiServerURL = "API_SERVER_URL"
  }

  // MARK: - Success Message
  public struct Success {
    public static let issue = "Your property rights have been registerred."
    public static let transfer = "Your bitmark have been transferring."
  }

  public struct Message {
    public static let sendingTransaction = "Sending your transaction to the Birmark network..."
    public static let transferringTransaction = "Transferring your bitmark to another account..."
  }
}
