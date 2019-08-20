//
//  BitmarkStep.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 8/19/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import RxFlow

enum BitmarkStep: Step {

  case appNavigation

  // Login/SignUp
  case userIsLoggedIn

  // Onboarding
  case onboardingIsRequired
  case accountIsRequired
  case testLogin
  case askingTouchFaceIdAuthentication
  case onboardingIsComplete

  case dashboardIsRequired

  // Bitmarks - Properties
  case listOfProperties
  case createProperty
  case createPropertyRights(assetURL: URL, assetFilename: String)
  case viewPropertyDescriptionInfo
  case issueIsComplete
  case viewTransferBitmark(bitmarkId: String, assetR: AssetR)
  case transferBitmarkIsComplete
  case deleteBitmarkIsComplete
  case scanOwnershipCode
  case viewBitmarkDetails(bitmarkR: BitmarkR, assetR: AssetR)
  case viewBitmarkAccountDetails(accountNumber: String)

  // Transactions
  case listOfTransactions
  case viewTransactionDetails(transactionR: TransactionR)

  // Account
  case viewAccountDetails
  case viewWarningWriteDownRecoveryPhrase
  case viewRecoveryPhrase
  case viewRecoveryPhraseIsComplete
  case testRecoveryPhrase
  case testRecoveryPhraseIsComplete
  case viewWarningRemoveAccess
  case viewRecoveryPhraseToRemoveAccess
  case testRecoveryPhraseToRemoveAccess
  case removeAccessIsComplete

  // App Details
  case viewAppDetails
  case viewTermsOfService
  case viewPrivacyPolicy
  case viewReleaseNotes
  case viewReleaseNotesIsComplete
}
