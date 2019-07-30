//
//  RegisterPropertyRightsViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/11/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK
import SnapKit
import Alamofire
import BEMCheckBox
import IQKeyboardManagerSwift

class RegisterPropertyRightsViewController: UIViewController, UITextFieldDelegate {

  // MARK: - Properties
  var assetR: AssetR?
  var assetData: Data!
  var assetFingerprint: String!
  var assetFileName: String?
  var assetURL: URL?

  var scrollView: UIScrollView!
  var assetFingerprintLabel: UILabel!
  var assetFilenameLabel: UILabel!
  var propertyNameTextField: DesignedTextField!
  var assetTypeTextField: BoxTextField!
  var metadataForms = [MetadataForm]()
  var metadataStackView: UIStackView!
  var metadataSettingButtons: UIStackView!
  var metadataAddButton: UIButton!
  var metadataEditModeButton: UIButton!
  var errorForMetadata: UILabel!
  var numberOfBitmarksTextField: DesignedTextField!
  var confirmCheckBox: BEMCheckBox!
  var errorForNumberOfBitmarksToIssue: UILabel!
  var issueButton: UIButton!
  var issueButtonBottomConstraint: Constraint!
  var networkReachabilityManager = NetworkReachabilityManager()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "REGISTER PROPERTY RIGHTS"
    navigationItem.backBarButtonItem = UIBarButtonItem()

    setupViews()
    setupEvents()

    // Add default Metadata
    if assetR == nil {
      setDefaultMetadataFormState()
      propertyNameTextField.becomeFirstResponder()
    } else {
      numberOfBitmarksTextField.becomeFirstResponder()
    }

    loadData()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    addNotificationObserver(name: UIWindow.keyboardWillShowNotification, selector: #selector(keyboardWillBeShow))
    addNotificationObserver(name: UIWindow.keyboardWillHideNotification, selector: #selector(keyboardWillBeHide))

    // *** setup network reachability handlers ****
    guard let networkReachabilityManager = networkReachabilityManager else { return }
    networkReachabilityManager.listener = { [weak self] status in
      guard let self = self else { return }
      switch status {
      case .reachable:
        self.issueButton.isEnabled = self.validToIssue()
        Global.hideNoInternetBanner()
      default:
        Global.showNoInternetBanner()
        self.issueButton.isEnabled = false
      }
    }
    networkReachabilityManager.startListening()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    removeNotificationsObserver()
  }

  // MARK: - Load Data
  fileprivate func loadData() {
    assetFingerprintLabel.text = assetFingerprint
    assetFilenameLabel.text = assetFileName

    if let assetR = assetR {
      propertyNameTextField.text = assetR.name

      var assetTypeValue: String?

      assetR.metadata.forEach { (metadataR) in
        metadataAddButton.sendActions(for: .touchUpInside)
        guard let metadataForm = metadataForms.last else { return }
        metadataForm.labelTextField.text = metadataR.key
        metadataForm.descriptionTextField.text = metadataR.value
        metadataForm.labelTextField.isEnabled = false
        metadataForm.descriptionTextField.isEnabled = false

        if metadataR.key == "source" {
          assetTypeValue = metadataR.value
        }
      }

      assetTypeTextField.text = assetTypeValue

      // Disable assetForm when asset has been existed
      propertyNameTextField.isEnabled = false
      assetTypeTextField.rightViewMode = .never
      metadataAddButton.removeFromSuperview()
      metadataEditModeButton.removeFromSuperview()
    }
  }

  // MARK: - Handlers
  // *** Asset Type ***
  @objc func showAssetTypePicker() {
    guard assetR == nil else { return }
    let alertController = UIAlertController()
    ["Photo", "Video", "File"].forEach { (assetType) in
      alertController.addAction(title: assetType, handler: selectAssetType)
    }
    alertController.addAction(title: "Cancel", style: .cancel, handler: selectAssetType)
    present(alertController, animated: true, completion: nil)
    assetTypeTextField.setStyle(state: .focus)
  }

  @objc func selectAssetType(_ sender: UIAlertAction) {
    guard let title = sender.title else { return }
    if title != "Cancel" {
      assetTypeTextField.text = sender.title
    } else if assetTypeTextField.isEmpty {
      assetTypeTextField.setStyle(state: .error)
    }

    guard let firstMetadataForm = metadataForms.first else { return }
    firstMetadataForm.labelTextField.becomeFirstResponder()
  }

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

    newMetadataForm.labelTextField.addTarget(self, action: #selector(metadataFieldEditingDidBegin), for: .editingDidBegin)
    newMetadataForm.descriptionTextField.addTarget(self, action: #selector(metadataFieldEditingDidBegin), for: .editingDidBegin)

    newMetadataForm.labelTextField.addTarget(self, action: #selector(metadataFieldEditingChanged), for: .editingChanged)
    newMetadataForm.descriptionTextField.addTarget(self, action: #selector(metadataFieldEditingChanged), for: .editingChanged)

    newMetadataForm.labelTextField.addTarget(self, action: #selector(metadataFieldEditingDidEnd), for: .editingDidEnd)
    newMetadataForm.descriptionTextField.addTarget(self, action: #selector(metadataFieldEditingDidEnd), for: .editingDidEnd)

    newMetadataForm.labelTextField.delegate = self
    newMetadataForm.descriptionTextField.delegate = self

    metadataStackView.addArrangedSubview(newMetadataForm)
    metadataForms.append(newMetadataForm)

    if assetR == nil {
      newMetadataForm.labelTextField.becomeFirstResponder()
    }
  }

  @objc func metadataFieldEditingDidBegin(_ tf: BoxTextField) {
    guard let currentMetadataForm = tf.parentView as? MetadataForm else { return }
    if currentMetadataForm.isBeginningState() {
      currentMetadataForm.setStyle(state: .focus)
    }
    changeMetadataViewMode(isOnEdit: false)
  }

  @objc func metadataFieldEditingChanged(_ tf: BoxTextField) {
    guard let currentMetadataForm = tf.parentView as? MetadataForm else { return }
    guard !currentMetadataForm.isDuplicated else { return } // if metadataForm is error cause duplication, keep as error
    if !tf.isEmpty {
      metadataSettingButtons.isHidden = false
      metadataEditModeButton.isHidden = false

      if !currentMetadataForm.siblingTextField(tf).isEmpty {
        metadataAddButton.isHidden = false
        metadataAddButton.isEnabled = true
        currentMetadataForm.setStyle(state: .success)
      }
    } else {
      metadataAddButton.isEnabled = false

      if !currentMetadataForm.siblingTextField(tf).isEmpty {
        currentMetadataForm.setStyle(state: .error)
      } else {
        currentMetadataForm.setStyle(state: .focus)
      }
    }
  }

  @objc func metadataFieldEditingDidEnd(_ tf: BoxTextField) {
    guard let currentMetadataForm = tf.parentView as? MetadataForm else { return }
    if currentMetadataForm.isBeginningState() {
      currentMetadataForm.setStyle(state: .default)
    } else {
      validateLabelDuplication()
    }
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

    let quantity = Int(numberOfBitmarksTextField.text!)!

    showIndicatorAlert(message: Constant.Message.sendingTransaction) { (selfAlert) in
      do {
        let assetId: String
        // *** Register Asset if asset has not existed; then issue ***
        if let assetR = self.assetR {
          assetId = assetR.id
          try AssetService.issueBitmarks(issuer: Global.currentAccount!, assetId: assetId, quantity: quantity)
        } else {
          let assetName = self.propertyNameTextField.text!
          var metadata = self.extractMetadataFromForms()
          metadata["source"] = self.assetTypeTextField.text!

          guard let fingerprint = self.assetData else { return }
          let assetInfo = (
            registrant: Global.currentAccount!,
            assetName: assetName,
            fingerprint: fingerprint,
            metadata: metadata
          )
          assetId = try AssetService.registerProperty(assetInfo: assetInfo, quantity: quantity)
        }

        self.moveFileToAppStorage(of: assetId)

        selfAlert.dismiss(animated: true, completion: {
          Global.syncNewDataInStorage()

          self.showQuickMessageAlert(message: Constant.Success.issue) { [weak self] in
            self?.navigationController?.popToRootViewController(animated: true)
          }
        })
      } catch {
        selfAlert.dismiss(animated: true, completion: {
          self.showErrorAlert(message: error.localizedDescription)
          ErrorReporting.report(error: error)
        })
      }
    }
  }

  func moveFileToAppStorage(of assetId: String) {
    guard let assetURL = assetURL else { return }
    do {
      try AssetFileService(owner: Global.currentAccount!, assetId: assetId)
                          .moveFileToAppStorage(fileURL: assetURL)
    } catch {
      ErrorReporting.report(error: error)
    }
  }

  @objc func dismissKeyboard() {
    view.endEditing(true)
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    view.endEditing(true)
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == propertyNameTextField {
      showAssetTypePicker()
      return true
    }

    if let textfield = textField as? BoxTextField,
       let currentMetadataForm = textfield.parentView as? MetadataForm {

      guard IQKeyboardManager.shared.goNext() else {
        guard let currentIndex = metadataForms.firstIndex(of: currentMetadataForm) else { return true }
        let nextIndex = currentIndex + 1
        if nextIndex >= metadataForms.count {
          return numberOfBitmarksTextField.becomeFirstResponder()
        } else {
          return metadataForms[nextIndex].labelTextField.becomeFirstResponder()
        }
      }
    }

    if textField == numberOfBitmarksTextField {
      return view.endEditing(true)
    }

    return true
  }
}

extension RegisterPropertyRightsViewController: MetadataFormDelegate {

  /**
   When user click to delete metadata cell in edit mode:
   1. remove the metadata form; turn off edit mode if there are none metadata form
   2. revalidate label duplication
   3. revalidate `Add Label` & `Issue` buttons
   */
  func deleteMetadataForm(hasUUID uuid: String) {
    showConfirmationAlert(message: Constant.Confirmation.deleteLabel) { [weak self] in
      guard let self = self, self.metadataForms.count >= 1 else { return }
      guard let deleteMetadataForm = self.metadataForms.filter({ $0.uuid == uuid }).first else { return }

      if self.metadataForms.count == 1 {
        deleteMetadataForm.setStyle(state: .default)
        self.changeMetadataViewMode(isOnEdit: false)
        self.metadataSettingButtons.isHidden =  true
        self.metadataAddButton.isHidden = true
        self.metadataEditModeButton.isHidden = true
        deleteMetadataForm.labelTextField.becomeFirstResponder()
      } else {
        deleteMetadataForm.removeFromSuperview() // 1
        self.metadataForms.removeAll(deleteMetadataForm)
      }

      self.validateLabelDuplication() // 2
      self.validateButtons()  // 3
    }
  }

  func validateButtons(isValid: Bool = true) {
    if isValid {
      let isMetadataValid = validMetadata()
      metadataAddButton.isEnabled = isMetadataValid
      issueButton.isEnabled = validToIssue()
    } else {
      metadataAddButton.isEnabled = false
      issueButton.isEnabled = false
    }
  }
}

extension RegisterPropertyRightsViewController: BEMCheckBoxDelegate {
  func didTap(_ checkBox: BEMCheckBox) {
    issueButton.isEnabled = validToIssue()
  }
}

// MARK: - Validate Form
extension RegisterPropertyRightsViewController {

  func validMetadata() -> Bool {
    return metadataForms.firstIndex(where: { !($0.isBeginningState() || $0.isValid) }) == nil
  }

  func validateLabelDuplication() {
    let duplicatedLabelForms: [MetadataForm] = getDuplicatedLabelForms()
    if duplicatedLabelForms.isEmpty {
      errorForMetadata.text = ""
      issueButton.isEnabled = validToIssue()
      metadataForms.forEach { $0.setStyle(state: .success) }
    } else {
      issueButton.isEnabled = false
      errorForMetadata.text = Constant.Error.Metadata.duplication

      for form in metadataForms {
        let isDuplicated = duplicatedLabelForms.contains(form)
        form.isDuplicated = isDuplicated
        form.setStyle(state: isDuplicated ? .error : .success)
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
    if assetR == nil {
      return !propertyNameTextField.isEmpty && !numberOfBitmarksTextField.isEmpty &&
              errorForNumberOfBitmarksToIssue.text?.isEmpty ?? true &&
              errorForMetadata.text?.isEmpty ?? true &&
              validMetadata() &&
              confirmCheckBox.on &&
              (networkReachabilityManager?.isReachable ?? false)
    } else {
      return !numberOfBitmarksTextField.isEmpty &&
             confirmCheckBox.on &&
             (networkReachabilityManager?.isReachable ?? false)
    }
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
  func setDefaultMetadataFormState() {
    metadataAddButton.sendActions(for: .touchUpInside)

    metadataAddButton.isHidden = true
    metadataEditModeButton.isHidden = true
  }

  func changeMetadataViewMode(isOnEdit: Bool) {
    metadataEditModeButton.isSelected = isOnEdit
    metadataForms.forEach { $0.isOnDeleteMode = isOnEdit }
  }

  private func extractMetadataFromForms() -> [String: String] {
    var metadataList = [String: String]()
    metadataForms.forEach { (form) in
      let metadata = form.getValues()
      if !metadata.label.isEmpty {
        metadataList[metadata.label] = metadata.description
      }
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

    confirmCheckBox.delegate = self

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

    issueButton = SubmitButton(title: "REGISTER")

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

    let inputFields = [
      propertyNameTextField, assetTypeTextField, numberOfBitmarksTextField, metadataStackView
    ]
    inputFields.forEach({ (inputField) in
      inputField?.snp.makeConstraints { $0.width.equalTo(mainView) }
    })

    let recognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    recognizer.cancelsTouchesInView = true
    view.addGestureRecognizer(recognizer)
  }

  fileprivate func setupMainView() -> UIStackView {
    return UIStackView(
      arrangedSubviews: [
        assetFingerpintView(),
        propertyNameView(),
        assetTypeView(),
        metadataView(),
        numberOfBitmarksView(),
        ownershipClaimView()
      ],
      axis: .vertical,
      spacing: 23,
      alignment: .leading,
      distribution: .fill
    )
  }

  fileprivate func assetFingerpintView() -> UIView {
    // *** Setup subviews ***
    let fieldLabel = CommonUI.inputFieldTitleLabel(text: "ASSET FINGERPRINT")

    assetFingerprintLabel = CommonUI.infoLabel(text: "Analyzing your file data...")
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

  fileprivate func assetTypeView() -> UIStackView {
    let fieldLabel = CommonUI.inputFieldTitleLabel(text: "ASSET TYPE")
    assetTypeTextField = BoxTextField(placeholder: "SELECT ASSET TYPE")
    assetTypeTextField.setPlaceHolderTextColor(.mainBlueColor)
    let downArrowImageView = UIImageView(image: UIImage(named: "arrow-down-tf"))
    downArrowImageView.frame = CGRect(x: 0, y: 0, width: downArrowImageView.size.width + 20.0, height: downArrowImageView.size.height)
    downArrowImageView.contentMode = .center
    assetTypeTextField.setStyle(state: .default)
    assetTypeTextField.isEnabled = false
    assetTypeTextField.rightView = downArrowImageView
    assetTypeTextField.rightViewMode = .always

    let assetTypeBox = UIView()
    assetTypeBox.addSubview(assetTypeTextField)
    assetTypeTextField.snp.makeConstraints({ $0.edges.equalToSuperview() })

    let assetTypeTapGesture = UITapGestureRecognizer(target: self, action: #selector(showAssetTypePicker))
    assetTypeBox.addGestureRecognizer(assetTypeTapGesture)

    return UIStackView(arrangedSubviews: [fieldLabel, assetTypeBox], axis: .vertical, spacing: 5)
  }

  fileprivate func metadataView() -> UIView {
    // *** Setup subviews ***
    let fieldLabel = CommonUI.inputFieldTitleLabel(text: "PROPERTY DESCRIPTION")

    let fieldInfoLink = UILabel(text: "What is property description? >>")
    fieldInfoLink.font = UIFont(name: "Avenir", size: 13)
    fieldInfoLink.textColor = .mainBlueColor

    let separateLine = UIView()
    separateLine.backgroundColor = .mainBlueColor

    metadataStackView = UIStackView(arrangedSubviews: [], axis: .vertical, spacing: 15)

    setupMetadataAddButton()
    setupMetadataEditModeButton()
    metadataSettingButtons = UIStackView(arrangedSubviews: [metadataAddButton, UIView(), metadataEditModeButton])
    metadataSettingButtons.isHidden = true

    errorForMetadata = CommonUI.errorFieldLabel()
    let errorForMetadataStackView = UIStackView(arrangedSubviews: [errorForMetadata])

    let metadataForms = UIStackView(arrangedSubviews: [metadataStackView, metadataSettingButtons], axis: .vertical, spacing: 7)

    // *** Setup view ***
    let view = UIView()
    view.addSubview(fieldLabel)
    view.addSubview(fieldInfoLink)
    view.addSubview(separateLine)
    view.addSubview(metadataForms)
    view.addSubview(errorForMetadataStackView)

    fieldLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    fieldInfoLink.snp.makeConstraints { (make) in
      make.top.equalTo(fieldLabel.snp.bottom)
      make.leading.trailing.equalToSuperview()
    }

    separateLine.snp.makeConstraints { (make) in
      make.top.equalTo(fieldInfoLink.snp.bottom).offset(-3)
      make.leading.equalToSuperview()
      make.width.equalTo(170)
      make.height.equalTo(0.5)
    }

    metadataForms.snp.makeConstraints { (make) in
      make.top.equalTo(separateLine.snp.bottom).offset(15)
      make.leading.trailing.equalToSuperview()
    }

    errorForMetadataStackView.snp.makeConstraints { (make) in
      make.top.equalTo(metadataForms.snp.bottom)
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
    confirmCheckBox = BEMCheckBox(frame: CGRect(x: 0, y: 0, width: 19, height: 19))
    confirmCheckBox.boxType = .square
    confirmCheckBox.animationDuration = 0.2

    let confirmCheckboxView = UIView()
    confirmCheckboxView.addSubview(confirmCheckBox)

    let description = CommonUI.descriptionLabel(text: "\"I hereby claim that I am the legal owner of this asset and want these properties rights to be irrevocably issued and recorded on the Bitmark blockchain.")

    let confirmView = UIStackView(arrangedSubviews: [confirmCheckboxView, description], axis: .horizontal, spacing: 5, alignment: .fill, distribution: .fillProportionally)
    confirmCheckboxView.snp.makeConstraints({ $0.width.equalTo(19) })
    description.snp.makeConstraints({ $0.width.equalToSuperview().offset(-28)})

    return UIStackView(arrangedSubviews: [fieldLabel, confirmView], axis: .vertical, spacing: 10)
  }

  fileprivate func setupMetadataAddButton() {
    metadataAddButton = UIButton(type: .system)
    metadataAddButton.titleLabel?.font = UIFont(name: "Courier", size: 13)
    metadataAddButton.setImage(UIImage(named: "add_label"), for: .normal)
    metadataAddButton.setImage(UIImage(named: "add_label_disabled"), for: .disabled)
    metadataAddButton.setTitle("ADD NEW FIELD", for: .normal)
    metadataAddButton.setTitleColor(.mainBlueColor, for: .normal)
    metadataAddButton.setTitleColor(.silver, for: .disabled)
    metadataAddButton.centerTextAndImage(spacing: 5.0)
    metadataAddButton.contentHorizontalAlignment = .left
    metadataAddButton.titleEdgeInsets.top = 2.0
  }

  fileprivate func setupMetadataEditModeButton() {
    metadataEditModeButton = UIButton()
    metadataEditModeButton.titleLabel?.font = UIFont(name: "Courier", size: 13)
    metadataEditModeButton.setTitle("EDIT", for: .normal)
    metadataEditModeButton.setTitle("DONE", for: .selected)
    metadataEditModeButton.setTitleColor(.mainBlueColor, for: .normal)
    metadataEditModeButton.titleEdgeInsets.top = 2.0
    metadataEditModeButton.isHidden = true
  }
}

// MARK: - KeyboardObserver
extension RegisterPropertyRightsViewController {
  @objc func keyboardWillBeShow(notification: Notification) {
    guard let userInfo = notification.userInfo else { return }
    guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

    issueButtonBottomConstraint.update(offset: -keyboardSize.height + view.safeAreaInsets.bottom)
    view.layoutIfNeeded()
  }

  @objc func keyboardWillBeHide(notification: Notification) {
    issueButtonBottomConstraint.update(offset: 0)
    view.layoutIfNeeded()
  }
}
