//
//  RegisterPropertyRightsViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/31/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class RegisterPropertyRightsViewController: UIViewController {

  // MARK: - Properties
  @IBOutlet weak var assetFingerprintLabel: UILabel!
  @IBOutlet weak var assetFilenameLabel: UILabel!
  @IBOutlet weak var propertyNameTextField: DesignedTextField!
  @IBOutlet weak var metaDataTableView: UITableView!
  @IBOutlet weak var metadataAddButton: UIButton!
  @IBOutlet weak var metadataEditButton: UIButton!
  @IBOutlet weak var numberOfBitmarksTextField: DesignedTextField!
  @IBOutlet weak var issueButton: UIButton!
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var bottomIssueButtonConstraint: NSLayoutConstraint!
  @IBOutlet weak var metaDataTableViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var errorForNumberOfBitmarksToIssue: UILabel!
  @IBOutlet weak var errorForMetadata: UILabel!

  var assetFile: UIImage!
  var assetFileName: String?
  lazy var assetFingerprintData: Data = {
    return assetFile.pngData()!
  }()

  let metaDataReuseIdentifier = "metaDataIdentifier"
  let selectLabelSegue = "selectLabelSegue"
  var isInEditMode = false
  let editButtonInEditMode = "DONE"
  let editButtonNotInEditMode = "EDIT"
  var numberOfMetaData = 0 {
    didSet {
      if numberOfMetaData == 0 {
        changeEditMode(isEditMode: false)
        metadataEditButton.isHidden = true
      } else {
        metadataEditButton.isHidden = false
      }
    }
  }
  let metaDataHeightPerItem: CGFloat = 80
  var selectedMetadataCell: MetaDataCell?
  var observers = NSPointerArray.weakObjects()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()
    loadData()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(true)
    registerNotifications()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    NotificationService.shared.removeNotifications(observers)
  }

  // MARK: - Handlers
  private func loadData() {
    assetFingerprintLabel.text = PropertyService.getFingerprintFrom(assetFingerprintData)
    assetFilenameLabel.text = assetFileName
  }

  // MARK: - Property Name
  @IBAction func typePropertyName(_ textfield: UITextField) {
    issueButton.isEnabled = validToIssue()
  }

  // MARK: - Metadata: Add/Edit/Delete
  /*
   When user tap "Add Label":
   1. disable "Add Label" & "Issue" button to require user fill into the incoming metadata cell
   2. add new metadata cell
   3. update metadataTableView height to fix current number of metadata cells
   */
  @IBAction func tapToAddLabel(_ button: UIButton) {
    metadataAddButton.isEnabled = false // 1
    issueButton.isEnabled = false
    numberOfMetaData += 1 // 2
    metaDataTableView.beginUpdates()
    let indexPath = IndexPath(row: numberOfMetaData - 1, section: 0)
    metaDataTableView.insertRows(at: [indexPath], with: .automatic)
    metaDataTableView.endUpdates()
    metaDataTableViewHeightConstraint.constant = CGFloat(numberOfMetaData) * metaDataHeightPerItem // 3
  }

  /*
   When user tap "Edit"/"Done" in metadata TableView:
   1. end editting for any editing textfield
   2. on/off edit mode
   */
  @IBAction func tapToEditMetadata(_ sender: UIButton) {
    view.endEditing(true)
    let isInEditMode = metadataEditButton.currentTitle == editButtonInEditMode
    let moveToEditMode = !isInEditMode
    changeEditMode(isEditMode: moveToEditMode)
  }

  // MARK: - Number of Issue
  @IBAction func typeQuantityBitmarkToIssue(_ sender: UITextField) {
    if let quantityText = sender.text, let quantity = Int(quantityText),
      let errorNumberOfBitmark = errorNumberOfBitmarksToIssue(quantity) {
      setNumberOfIssuesBoxStyle(with: errorNumberOfBitmark)
      issueButton.isEnabled = false
    } else {
      setNumberOfIssuesBoxStyle()
      issueButton.isEnabled = validToIssue()
    }
  }

  // MARK: - Issue
  @IBAction func tapToIssue(_ sender: UIButton) {
    let assetName = propertyNameTextField.text!
    let metadata = extractMetaData()
    let quantity = Int(numberOfBitmarksTextField.text!)!

    do {
      let assetId = try PropertyService.registerAsset(registrant: Global.currentAccount!, assetName: assetName, fingerprint: assetFingerprintData, metadata: metadata)
      let _ = try PropertyService.issueBitmarks(issuer: Global.currentAccount!, assetId: assetId, quantity: quantity)
    } catch let e {
      showErrorAlert(message: e.localizedDescription)
    }
  }

  // MARK: - General
  @IBAction func tapPiece(_ recognizer: UITapGestureRecognizer) {
    view.endEditing(true)
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    view.endEditing(true)
  }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension RegisterPropertyRightsViewController: UITableViewDataSource, UITableViewDelegate, MetaDataCellDelegate, MetadataLabelUpdationDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return numberOfMetaData
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: metaDataReuseIdentifier, for: indexPath) as! MetaDataCell
    cell.styleCell(in: view)
    cell.displayDeleteView(isShow: isInEditMode)
    cell.delegate = self
    return cell
  }

  /*
   When user tap into Label Textfield in metaData
   - gotoUpdateLabel: go to MetadataLabelViewController Screen
   - updateMetadataLabel with label from MetadataLabelViewController Screen
   */
  func gotoUpdateLabel(from cell: MetaDataCell) {
    selectedMetadataCell = cell
    performSegue(withIdentifier: selectLabelSegue, sender: nil)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == selectLabelSegue, let destination = segue.destination as? MetadataLabelViewController {
      destination.metadataLabel = selectedMetadataCell?.labelTextField.text
      destination.delegate = self
    }
  }

  func updateMetadataLabel(_ label: String) {
    if let selectedMetadataCell = selectedMetadataCell {
      selectedMetadataCell.setLabel(label)
      validateLabelDuplication()
    }
  }

  func adjustRelatedButtonsState() {
    metadataAddButton.isEnabled = validMetadata()
    issueButton.isEnabled = validToIssue()
  }

  /*
   When user click to delete metadata cell in edit mode:
   1. remove the metadata cell
   2. update metadataTableView height to fix current number of metadata cells
   3. adjust "Add label" & "Issue" buttons
   4. revalidate label duplication
   */
  func removeCell(_ cell: MetaDataCell) {
    showConfirmationAlert(message: Constant.Confirmation.deleteLabel) {
      self.numberOfMetaData -= 1 // 1
      let indexPath = self.metaDataTableView.indexPath(for: cell)!
      self.metaDataTableView.beginUpdates()
      self.metaDataTableView.deleteRows(at: [indexPath], with: .automatic)
      self.metaDataTableView.endUpdates()
      self.metaDataTableViewHeightConstraint.constant = CGFloat(self.numberOfMetaData) * self.metaDataHeightPerItem // 2
      self.adjustRelatedButtonsState() // 3
      self.validateLabelDuplication() // 4
    }
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return metaDataHeightPerItem
  }
}

// MARK: - Validate Form
extension RegisterPropertyRightsViewController {
  func errorNumberOfBitmarksToIssue(_ quantity: Int) -> String? {
    if quantity <= 0 {
      return Constant.Error.NumberOfBitmarks.minimumQuantity
    } else if quantity > 100 {
      return Constant.Error.NumberOfBitmarks.maxinumQuantity
    }
    return nil
  }

  func validToIssue() -> Bool {
    if propertyNameTextField.text!.count > 0, numberOfBitmarksTextField.text!.count > 0,
       errorForNumberOfBitmarksToIssue.text == "",
       validMetadata() && errorForMetadata.text == "" {
      return true
    }
    return false
  }

  func validMetadata() -> Bool {
    for row in 0..<numberOfMetaData {
      let indexPath = IndexPath(row: row, section: 0)
      let cell = metaDataTableView.cellForRow(at: indexPath) as! MetaDataCell
      if !cell.isValid { return false }
    }
    return true
  }

  func validateLabelDuplication() {
    let duplicatedLabelCells: [MetaDataCell] = getDuplicatedLabelCells()
    if duplicatedLabelCells.count > 0 {
      issueButton.isEnabled = false
      errorForMetadata.text = Constant.Error.Metadata.duplication
      for cell in (metaDataTableView.visibleCells as! [MetaDataCell]) {
        let isDuplicated = duplicatedLabelCells.contains(cell)
        cell.setDuplicatedStyle(isDuplicated: isDuplicated)
      }
    } else {
      errorForMetadata.text = ""
      issueButton.isEnabled = validToIssue()
      for cell in (metaDataTableView.visibleCells as! [MetaDataCell]) {
        cell.setDuplicatedStyle(isDuplicated: false)
      }
    }
  }

  func getDuplicatedLabelCells() -> [MetaDataCell] {
    // create dictionary with key is label, value is cells which has the label
    var metadataLabelList = [String: [MetaDataCell]]()
    for cell in (metaDataTableView.visibleCells as! [MetaDataCell]) {
      let label = cell.labelTextField.text!
      guard label != "" else { continue }
      var currentCellsForLabel = metadataLabelList[label] ?? []
      currentCellsForLabel.append(cell)
      metadataLabelList[label] = currentCellsForLabel
    }

    // get all cells has duplicated labels
    var duplicatedCells = [MetaDataCell]()
    for (_, cellsForLabel) in metadataLabelList {
      if cellsForLabel.count > 1 { duplicatedCells += cellsForLabel }
    }
    return duplicatedCells
  }

  func setNumberOfIssuesBoxStyle(with errorMessage: String? = nil) {
    if let errorMessage = errorMessage {
      errorForNumberOfBitmarksToIssue.text = errorMessage
      numberOfBitmarksTextField.textColor = .mainRedColor
      numberOfBitmarksTextField.borderLineColor = .mainRedColor
    } else {
      errorForNumberOfBitmarksToIssue.text = ""
      numberOfBitmarksTextField.textColor = .black
      numberOfBitmarksTextField.borderLineColor = .mainBlueColor
    }
  }
}

// MARK: - UITextFieldDelegate
extension RegisterPropertyRightsViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

// MARK: - KeyboardObserver
extension RegisterPropertyRightsViewController: KeyboardObserver {
  private func registerNotifications() {
    for observer in registerForKeyboardNotifications() {
      NotificationService.shared.addNotification(in: &observers, with: observer)
    }
  }

  func keyboardWillBeShow(notification: Notification) {
    guard let userInfo = notification.userInfo else { return }
    let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
    bottomIssueButtonConstraint.constant = keyboardSize.height - view.safeAreaInsets.bottom
    updateLayoutWithKeyboard()
  }

  func keyboardWillBeHide(notification: Notification) {
    bottomIssueButtonConstraint.constant = 0.0
    updateLayoutWithKeyboard()
  }
}

// MARK: - Supporter
extension RegisterPropertyRightsViewController {
  func changeEditMode(isEditMode: Bool) {
    isInEditMode = isEditMode
    let editButtonText = isEditMode ? editButtonInEditMode : editButtonNotInEditMode
    metadataEditButton.setTitle(editButtonText, for: .normal)

    for cell in metaDataTableView.visibleCells as! [MetaDataCell] {
      cell.displayDeleteView(isShow: isEditMode)
    }
  }

  private func extractMetaData() -> [String: String] {
    var metadataList = [String: String]()
    for cell in (metaDataTableView.visibleCells as! [MetaDataCell]) {
      let metadata = cell.getValues()
      guard metadata.label != "" else { continue }
      metadataList[metadata.label] = metadata.description
    }
    return metadataList
  }
}
