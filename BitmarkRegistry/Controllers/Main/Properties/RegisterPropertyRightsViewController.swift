//
//  RegisterPropertyRightsViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import SnapKit

class RegisterPropertyRightsViewController: UIViewController, UITextFieldDelegate {

  // MARK: - Properties
  var assetFile: UIImage!
  var assetFileName: String?
  lazy var assetFingerprintData: Data = {
    return assetFile.pngData()!
  }()

  var scrollView: UIScrollView!
  var assetFingerprintLabel: UILabel!
  var assetFilenameLabel: UILabel!
  var propertyNameTextField: DesignedTextField!
  var metadataForms = [MetadataForm]() {
    didSet {
      metadataEditModeButton.isHidden = self.metadataForms.isEmpty
    }
  }
  var isMetadataViewOnEditMode: Bool {
    get {
      return metadataEditModeButton.isSelected
    }
  }
  var metadataStackView: UIStackView!
  var metadataAddButton: UIButton!
  var metadataEditModeButton: UIButton!
  var selectedMetadataForm: MetadataForm?
  var errorForMetadata: UILabel!
  var numberOfBitmarksTextField: DesignedTextField!
  var errorForNumberOfBitmarksToIssue: UILabel!
  var issueButton: UIButton!
  var issueButtonBottomConstraint: Constraint!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "REGISTER PROPERTY RIGHTS"
    navigationItem.backBarButtonItem = UIBarButtonItem()

    setupViews()
    setupEvents()

    loadData()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    addNotificationObserver(name: UIWindow.keyboardWillShowNotification, selector: #selector(keyboardWillBeShow))
    addNotificationObserver(name: UIWindow.keyboardWillHideNotification, selector: #selector(keyboardWillBeHide))
  }

  override func viewWillDisappear(_ animated: Bool) {
    removeNotificationsObserver()
  }

  // MARK: - Load Data
  fileprivate func loadData() {
    assetFingerprintLabel.text = AssetService.getFingerprintFrom(assetFingerprintData)
    assetFilenameLabel.text = assetFileName
  }

  // MARK: - Handlers
  /**
   When user tap **Add Label**:
   1. disable `Add Label` & `Issue` button to require user fill into the incoming metadata form
   2. add new metadata form
   */
  @objc func addMetadataForm(_ sender: UIButton) {
    metadataAddButton.isEnabled = false // 1
    issueButton.isEnabled = false

    let newMetadataForm = MetadataForm(uuid: UUID().uuidString) // 2
    newMetadataForm.delegate = self
    newMetadataForm.isOnDeleteMode = isMetadataViewOnEditMode
    metadataStackView.addArrangedSubview(newMetadataForm)
    metadataForms.append(newMetadataForm)
  }

  @objc func setModeMetadataForm(_ sender: UIButton) {
    changeMetadataViewMode(isOnEdit: !metadataEditModeButton.isSelected)
  }

  @objc func editingTextField(_ textfield: UITextField) {
    issueButton.isEnabled = validToIssue()
  }

  @objc func typeNumberOfBitmarkToIssue(_ sender: UITextField) {
    if let quantityText = sender.text, let quantity = Int(quantityText),
      let errorNumberOfBitmark = errorNumberOfBitmarksToIssue(quantity) {
      setNumberOfBitmarksBoxStyle(with: errorNumberOfBitmark)
      issueButton.isEnabled = false
    } else {
      setNumberOfBitmarksBoxStyle()
      issueButton.isEnabled = validToIssue()
    }
  }

  @objc func tapToIssue(_ button: UIButton) {
    view.endEditing(true)

    let assetName = propertyNameTextField.text!
    let metadata = extractMetadataFromForms()
    let quantity = Int(numberOfBitmarksTextField.text!)!
    var errorMessage: String? = nil

    let alert = showIndicatorAlert(message: Constant.Message.sendingTransaction) {
      do {
        let assetId = try AssetService.registerAsset(
          registrant: Global.currentAccount!,
          assetName: assetName,
          fingerprint: self.assetFingerprintData,
          metadata: metadata)
        let _ = try AssetService.issueBitmarks(
          issuer: Global.currentAccount!,
          assetId: assetId,
          quantity: quantity)
      } catch let e {
        errorMessage = e.localizedDescription
      }
    }

    // show result alert
    alert.dismiss(animated: true) {
      if let errorMessage = errorMessage {
        self.showErrorAlert(message: errorMessage)
      } else {
        self.showSuccessAlert(message: Constant.Success.issue, handler: {
          self.navigationController?.popToRootViewController(animated: true)
        })
      }
    }
  }

  @objc func dismissKeyboard() {
    view.endEditing(true)
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    view.endEditing(true)
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    return view.endEditing(true)
  }
}

extension RegisterPropertyRightsViewController: MetadataFormDelegate, MetadataLabelUpdationDelegate {
  func gotoUpdateLabel(from form: MetadataForm) {
    selectedMetadataForm = form
    let metadataLabelViewController = MetadataLabelViewController()
    metadataLabelViewController.metadataLabel = form.labelTextField.text!
    metadataLabelViewController.delegate = self

    navigationController?.pushViewController(metadataLabelViewController)
  }

  func updateMetadataLabel(_ label: String) {
    if let selectedMetadataForm = selectedMetadataForm {
      selectedMetadataForm.setLabel(label)
      validateLabelDuplication()
    }
  }

  /**
   When user click to delete metadata cell in edit mode:
   1. remove the metadata form; turn off edit mode if there are none metadata form
   2. revalidate label duplication
   3. revalidate `Add Label` & `Issue` buttons
   */
  func deleteMetadataForm(hasUUID uuid: String) {
    showConfirmationAlert(message: Constant.Confirmation.deleteLabel) {
      let deleteMetadataForm = self.metadataForms.filter({ $0.uuid == uuid }).first!
      deleteMetadataForm.removeFromSuperview() // 1
      self.metadataForms.removeAll(deleteMetadataForm)
      if self.metadataForms.isEmpty {
        self.changeMetadataViewMode(isOnEdit: false)
      }
      self.validateLabelDuplication() // 2
      self.validateButtons()  // 3
    }
  }

  func validateButtons(isValid: Bool = true) {
    if isValid {
      metadataAddButton.isEnabled = validMetadata()
      issueButton.isEnabled = validToIssue()
    } else {
      metadataAddButton.isEnabled = false
      issueButton.isEnabled = false
    }
  }
}

// MARK: - Validate Form
extension RegisterPropertyRightsViewController {

  func validMetadata() -> Bool {
    for metadataForm in metadataForms {
      if !metadataForm.isValid { return false }
    }
    return true
  }

  func validateLabelDuplication() {
    let duplicatedLabelForms: [MetadataForm] = getDuplicatedLabelForms()
    if duplicatedLabelForms.isEmpty {
      errorForMetadata.text = ""
      issueButton.isEnabled = validToIssue()
      metadataForms.forEach { $0.setDuplicatedStyle(isDuplicated: false) }
    } else {
      issueButton.isEnabled = false
      errorForMetadata.text = Constant.Error.Metadata.duplication

      for form in metadataForms {
        let isDuplicated = duplicatedLabelForms.contains(form)
        form.setDuplicatedStyle(isDuplicated: isDuplicated)
      }
    }
  }

  func getDuplicatedLabelForms() -> [MetadataForm] {
    let groupByLabel = Dictionary(grouping: metadataForms, by: { $0.labelTextField.text })

    return groupByLabel.reduce(into: [MetadataForm](), { (duplicatedForms, keyValue) in
      let (label, forms) = keyValue
      if let label = label, !label.isEmpty && forms.count > 1 {
        duplicatedForms += forms
      }
    })
  }

  func errorNumberOfBitmarksToIssue(_ quantity: Int) -> String? {
    if quantity <= 0 {
      return Constant.Error.NumberOfBitmarks.minimumQuantity
    } else if quantity > 100 {
      return Constant.Error.NumberOfBitmarks.maxinumQuantity
    }
    return nil
  }

  func validToIssue() -> Bool {
    if !propertyNameTextField.isEmpty, !numberOfBitmarksTextField.isEmpty,
       errorForNumberOfBitmarksToIssue.text?.isEmpty ?? true,
       errorForMetadata.text?.isEmpty ?? true,
       validMetadata() {
      return true
    }
    return false
  }

  func setNumberOfBitmarksBoxStyle(with errorMessage: String? = nil) {
    if let errorMessage = errorMessage {
      errorForNumberOfBitmarksToIssue.text = errorMessage
      numberOfBitmarksTextField.onErrorStyle()
    } else {
      errorForNumberOfBitmarksToIssue.text = ""
      numberOfBitmarksTextField.offErrorStyle()
    }
  }
}

// MARK: - Support Functions
extension RegisterPropertyRightsViewController {
  func changeMetadataViewMode(isOnEdit: Bool) {
    metadataEditModeButton.isSelected = isOnEdit
    metadataForms.forEach { $0.isOnDeleteMode = isOnEdit }
  }

  private func extractMetadataFromForms() -> [String: String] {
    var metadataList = [String: String]()
    metadataForms.forEach { (form) in
      let metadata = form.getValues()
      metadataList[metadata.label] = metadata.description
    }
    return metadataList
  }
}

// MARK: - Setup Views/Events
extension RegisterPropertyRightsViewController {
  fileprivate func setupEvents() {
    propertyNameTextField.delegate = self
    propertyNameTextField.addTarget(self, action: #selector(editingTextField), for: .editingChanged)

    metadataAddButton.addTarget(self, action: #selector(addMetadataForm), for: .touchUpInside)
    metadataEditModeButton.addTarget(self, action: #selector(setModeMetadataForm), for: .touchUpInside)

    numberOfBitmarksTextField.delegate = self
    numberOfBitmarksTextField.addTarget(self, action: #selector(typeNumberOfBitmarkToIssue), for: .editingChanged)
    numberOfBitmarksTextField.addTarget(self, action: #selector(editingTextField), for: .editingChanged)

    issueButton.addTarget(self, action: #selector(tapToIssue), for: .touchUpInside)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    let mainView = setupMainView()

    scrollView = UIScrollView()

    scrollView.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 25, right: 20))
      make.width.equalToSuperview().offset(-40)
    }

    issueButton = SubmitButton(title: "ISSUE")

    view.addSubview(scrollView)
    view.addSubview(issueButton)

    scrollView.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
    }

    issueButton.snp.makeConstraints { (make) in
      make.top.equalTo(scrollView.snp.bottom)
      make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
      self.issueButtonBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).constraint
    }

    propertyNameTextField.snp.makeConstraints { $0.width.equalTo(mainView) }
    numberOfBitmarksTextField.snp.makeConstraints { $0.width.equalTo(mainView) }
    metadataStackView.snp.makeConstraints { $0.width.equalTo(mainView) }

    let recognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    recognizer.cancelsTouchesInView = true
    view.addGestureRecognizer(recognizer)
  }

  fileprivate func setupMainView() -> UIStackView {
    return UIStackView(
      arrangedSubviews: [
        assetFingerpintView(),
        propertyNameView(),
        metadataView(),
        numberOfBitmarksView(),
        ownershipClaimView()
      ],
      axis: .vertical,
      spacing: 30,
      alignment: .leading,
      distribution: .fill
    )
  }

  fileprivate func assetFingerpintView() -> UIView {
    // *** Setup subviews ***
    let fieldLabel = CommonUI.inputFieldTitleLabel(text: "ASSET FINGERPRINT")

    assetFingerprintLabel = CommonUI.infoLabel()
    assetFingerprintLabel.textColor = .mainBlueColor

    let generatedFromLabel = UILabel()
    generatedFromLabel.text = "GENERATED FROM"
    generatedFromLabel.font = UIFont(name: "Avenir-Light", size: 14)
    generatedFromLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

    assetFilenameLabel = UILabel()
    assetFilenameLabel.font = UIFont(name: "Avenir-Black", size: 14)

    let generatedFromStackView = UIStackView(
      arrangedSubviews: [generatedFromLabel, assetFilenameLabel], axis: .horizontal, spacing: 5)

    // *** Setup view ***
    let assetFingerpintView = UIView()
    assetFingerpintView.addSubview(fieldLabel)
    assetFingerpintView.addSubview(assetFingerprintLabel)
    assetFingerpintView.addSubview(generatedFromStackView)

    fieldLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    assetFingerprintLabel.snp.makeConstraints { (make) in
      make.top.equalTo(fieldLabel.snp.bottom).offset(8)
      make.leading.trailing.width.equalToSuperview()
    }

    generatedFromStackView.snp.makeConstraints { (make) in
      make.top.equalTo(assetFingerprintLabel.snp.bottom).offset(5)
      make.leading.trailing.bottom.equalToSuperview()
    }

    return assetFingerpintView
  }

  fileprivate func propertyNameView() -> UIStackView {
    let fieldLabel = CommonUI.inputFieldTitleLabel(text: "PROPERTY NAME")
    propertyNameTextField = DesignedTextField(placeholder: "64-CHARACTER MAX")
    propertyNameTextField.returnKeyType = .done

    return UIStackView(arrangedSubviews: [fieldLabel, propertyNameTextField], axis: .vertical, spacing: 15)
  }

  fileprivate func metadataView() -> UIView {
    // *** Setup subviews ***
    let fieldLabel = CommonUI.inputFieldTitleLabel(text: "METADATA")
    let fieldTitleLabel = CommonUI.fieldTitleLabel(text: "OPTIONAL PROPERTY METADATA (2048-BYTE LIMIT)")

    metadataStackView = UIStackView(arrangedSubviews: [], axis: .vertical, spacing: 15)

    metadataAddButton = UIButton()
    metadataAddButton.titleLabel?.font = UIFont(name: "Courier", size: 13)
    metadataAddButton.setImage(UIImage(named: "add_label"), for: .normal)
    metadataAddButton.setImage(UIImage(named: "add_label_disabled"), for: .disabled)
    metadataAddButton.setTitle("ADD LABEL", for: .normal)
    metadataAddButton.setTitleColor(.mainBlueColor, for: .normal)
    metadataAddButton.setTitleColor(.silver, for: .disabled)
    metadataAddButton.centerTextAndImage(spacing: 5.0)
    metadataAddButton.contentHorizontalAlignment = .left
    metadataAddButton.titleEdgeInsets.top = 2.0

    metadataEditModeButton = UIButton()
    metadataEditModeButton.titleLabel?.font = UIFont(name: "Courier", size: 13)
    metadataEditModeButton.setTitle("EDIT", for: .normal)
    metadataEditModeButton.setTitle("DONE", for: .selected)
    metadataEditModeButton.setTitleColor(.mainBlueColor, for: .normal)
    metadataEditModeButton.titleEdgeInsets.top = 2.0
    metadataEditModeButton.isHidden = true

    let settingButtons = UIStackView(arrangedSubviews: [metadataAddButton, UIView(), metadataEditModeButton])

    errorForMetadata = CommonUI.errorFieldLabel()
    let errorForMetadataStackView = UIStackView(arrangedSubviews: [errorForMetadata])

    // *** Setup view ***
    let view = UIView()
    view.addSubview(fieldLabel)
    view.addSubview(fieldTitleLabel)
    view.addSubview(metadataStackView)
    view.addSubview(settingButtons)
    view.addSubview(errorForMetadataStackView)

    fieldLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    fieldTitleLabel.snp.makeConstraints { (make) in
      make.top.equalTo(fieldLabel.snp.bottom).offset(8)
      make.leading.trailing.equalToSuperview()
    }

    metadataStackView.snp.makeConstraints { (make) in
      make.top.equalTo(fieldTitleLabel.snp.bottom).offset(10)
      make.leading.trailing.equalToSuperview()
    }

    settingButtons.snp.makeConstraints { (make) in
      make.top.equalTo(metadataStackView.snp.bottom)
      make.leading.trailing.equalToSuperview()
    }

    errorForMetadataStackView.snp.makeConstraints { (make) in
      make.top.equalTo(settingButtons.snp.bottom)
      make.leading.trailing.bottom.equalToSuperview()
    }

    return view
  }

  fileprivate func numberOfBitmarksView() -> UIStackView {
    let fieldLabel = CommonUI.inputFieldTitleLabel(text: "NUMBER OF BITMARKS TO ISSUE")
    numberOfBitmarksTextField = DesignedTextField(placeholder: "1~100 BITMARKS")
    numberOfBitmarksTextField.keyboardType = .numberPad
    numberOfBitmarksTextField.returnKeyType = .done

    let flexBar = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
    let bar = UIToolbar()
    bar.sizeToFit()
    bar.items = [flexBar, doneButton]
    numberOfBitmarksTextField.inputAccessoryView = bar

    errorForNumberOfBitmarksToIssue = CommonUI.errorFieldLabel()

    return UIStackView(arrangedSubviews: [fieldLabel, numberOfBitmarksTextField, errorForNumberOfBitmarksToIssue], axis: .vertical, spacing: 15)
  }

  fileprivate func ownershipClaimView() -> UIStackView {
    let fieldLabel = CommonUI.inputFieldTitleLabel(text: "OWNERSHIP CLAIM")
    let description = CommonUI.descriptionLabel(text: "\"I hereby claim that I am the legal owner of this asset and want these properties rights to be irrevocably issued and recorded on the Bitmark blockchain.")

    return UIStackView(arrangedSubviews: [fieldLabel, description], axis: .vertical, spacing: 15)
  }
}

// MARK: - KeyboardObserver
extension RegisterPropertyRightsViewController {
  @objc func keyboardWillBeShow(notification: Notification) {
    guard let userInfo = notification.userInfo else { return }
    let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect

    issueButtonBottomConstraint.update(offset: -keyboardSize.height + view.safeAreaInsets.bottom)
    view.layoutIfNeeded()

    metadataAddButton.isUserInteractionEnabled = false
    metadataEditModeButton.isUserInteractionEnabled = false
  }

  @objc func keyboardWillBeHide(notification: Notification) {
    issueButtonBottomConstraint.update(offset: 0)
    view.layoutIfNeeded()

    metadataAddButton.isUserInteractionEnabled = true
    metadataEditModeButton.isUserInteractionEnabled = true
  }
}
