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
import RxSwift
import RxFlow
import RxCocoa

class RegisterPropertyRightsViewController: UIViewController, UITextFieldDelegate, Stepper {
  var steps = PublishRelay<Step>()

  // MARK: - Properties
  var assetFileName: String!
  var assetURL: URL!
  lazy var assetURLObservable: Observable<URL> = {
    return Observable.just(assetURL!)
  }()

  var assetDataObservable: Observable<Data>!
  var assetFingerprintObservable: Observable<String>!
  var assetRVariable = BehaviorRelay<AssetR?>(value: nil)
  var scrollView: UIScrollView!
  var assetFingerprintLabel: UILabel!
  var assetFilenameLabel: UILabel!
  var propertyNameTextField: DesignedTextField!
  var assetTypeTextField: BoxTextField!
  var downArrowAssetTypeSelection: UIButton!
  var metadataForms = [MetadataForm]()
  var metadataStackView: UIStackView!
  var metadataSettingButtons: UIStackView!
  var metadataAddButton: UIButton!
  var metadataEditModeButton: UIButton!
  var errorForMetadata: UILabel!
  var numberOfBitmarksBox: UIView!
  var numberOfBitmarksTextField: GMStepper!
  var confirmCheckBox: BEMCheckBox!
  var issueButton: UIButton!
  var issueButtonBottomConstraint: Constraint!
  var disabledScreen: UIView!
  var activityIndicator: UIActivityIndicatorView!
  let transparentNavBackButton = CommonUI.transparentNavBackButton()
  var networkReachabilityManager = NetworkReachabilityManager()
  let disposeBag = DisposeBag()

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = "registerPropertyRights_title".localized(tableName: "Phrase").localizedUppercase
    navigationItem.backBarButtonItem = UIBarButtonItem()

    setupViews()
    setupEvents()
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

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    transparentNavBackButton.addTarget(self, action: #selector(tapBackNav), for: .touchUpInside)
    navigationController?.navigationBar.addSubview(transparentNavBackButton)

    activityIndicator.startAnimating()
    disabledScreen.isHidden = false

    assetDataObservable = assetURLObservable
      .observeOn(MainScheduler.asyncInstance)
      .map { try Data(contentsOf: $0) }
      .share(replay: 1, scope: .forever)

    assetFingerprintObservable = assetDataObservable
      .observeOn(MainScheduler.asyncInstance)
      .map { AssetService.getFingerprintFrom($0) }
      .share(replay: 1, scope: .forever)

    assetFingerprintObservable
      .observeOn(MainScheduler.asyncInstance)
      .map { AssetService.getAsset(from: $0) }
      .bind(to: assetRVariable)
      .disposed(by: disposeBag)

    loadData()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    transparentNavBackButton.removeFromSuperview()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    removeNotificationsObserver()
  }

  @objc func tapBackNav(_ sender: UIBarButtonItem) {
    let discardRegistrationConfirmation = UIAlertController(
      title: "registerPropertyRights_discardConfirmationTitle".localized(tableName: "Phrase"),
      message: "registerPropertyRights_discardConfirmationMessage".localized(tableName: "Phrase"),
      preferredStyle: .alert
    )
    let discardAction = UIAlertAction(title: "Discard".localized(), style: .default) { [weak self] (_) in
      self?.steps.accept(BitmarkStep.endCreatePropertyRights)
    }

    let stayAction = UIAlertAction(title: "Stay".localized(), style: .default, handler: nil)

    discardRegistrationConfirmation.addAction(discardAction)
    discardRegistrationConfirmation.addAction(stayAction)
    discardRegistrationConfirmation.preferredAction = stayAction
    discardRegistrationConfirmation.show()
  }

  // MARK: - Load Data
  fileprivate func loadData() {
    assetFilenameLabel.text = assetFileName

    assetFingerprintObservable
      .bind(to: assetFingerprintLabel.rx.text)
      .disposed(by: disposeBag)

    assetRVariable.asObservable().skip(1)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] (assetR) in
      guard let self = self else { return }
      if let assetR = assetR {
        self.loadAssetRData(assetR)
      } else {
        self.setupDefaultForm()
      }
      self.activityIndicator.stopAnimating()
      self.disabledScreen.isHidden = true
    })
    .disposed(by: disposeBag)
  }

  fileprivate func loadAssetRData(_ assetR: AssetR) {
    propertyNameTextField.text = assetR.name

    var assetTypeValue: String?

    assetR.metadata.forEach { (metadataR) in
      metadataAddButton.sendActions(for: .touchUpInside)
      guard let metadataForm = metadataForms.last else { return }
      metadataForm.labelTextField.text = metadataR.key
      metadataForm.descriptionTextField.text = metadataR.value
      metadataForm.labelTextField.isEnabled = false
      metadataForm.descriptionTextField.isEnabled = false

      if metadataR.key.caseInsensitiveCompare("source") == .orderedSame {
        assetTypeValue = metadataR.value
      }
    }

    assetTypeTextField.text = assetTypeValue

    // Disable assetForm when asset has been existed
    propertyNameTextField.isEnabled = false
    assetTypeTextField.rightViewMode = .never
    assetTypeTextField.isEnabled = false
    assetTypeTextField.placeholder = ""
    metadataAddButton.removeFromSuperview()
    metadataEditModeButton.removeFromSuperview()
  }

  fileprivate func setupDefaultForm() {
    addMetadataForm(isDefault: true)
    metadataAddButton.isHidden = true
    metadataEditModeButton.isHidden = true
    scrollView.setContentOffset(CGPoint.zero, animated: false)
    propertyNameTextField.becomeFirstResponder()
  }

  // MARK: - Handlers
  // *** Asset Type ***
  @objc func showAssetTypePicker() {
    guard assetRVariable.value == nil else { return }
    assetTypeTextField.setPlaceHolderTextColor(.mainBlueColor)
    downArrowAssetTypeSelection.isSelected = true
    let alertController = UIAlertController()
    [
      "Photo".localized(), "Video".localized(),"File".localized()
    ].forEach { (assetType) in
      alertController.addAction(title: assetType, handler: selectAssetType)
    }
    alertController.addAction(title: "Cancel".localized(), style: .cancel, handler: selectAssetType)
    present(alertController, animated: true, completion: nil)
    assetTypeTextField.setStyle(state: .focus)
  }

  @objc func selectAssetType(_ sender: UIAlertAction) {
    guard let title = sender.title else { return }
    if title != "Cancel".localized() {
      assetTypeTextField.text = sender.title?.uppercased()
      issueButton.isEnabled = validToIssue()
    } else if assetTypeTextField.isEmpty {
      assetTypeTextField.setStyle(state: .error)
    }

    guard let firstMetadataForm = metadataForms.first else { return }
    firstMetadataForm.labelTextField.becomeFirstResponder()
  }

  // *** Metadata Form ***
  @objc func goToPropertyDescriptionInfo(_ sender: UIButton) {
    steps.accept(BitmarkStep.viewPropertyDescriptionInfo)
  }

  /**
   When user tap **Add Label**:
   1. disable `Add Label` & `Issue` button to require user fill into the incoming metadata form
   2. add new metadata form
   */
  @objc func tapToAddMetadataForm(_ sender: UIButton) {
    addMetadataForm()
  }

  fileprivate func addMetadataForm(isDefault: Bool = false) {
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

    view.endEditing(true)

    if assetRVariable.value == nil && !isDefault {
      newMetadataForm.labelTextField.becomeFirstResponder()

      // adjust scroll to help user still able to click "Add new field" without needing scroll down
      var scrollContentOffset = scrollView.contentOffset
      scrollContentOffset.y += 85.0
      scrollView.setContentOffset(scrollContentOffset, animated: true)
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
    let isSiblingTfEmpty = currentMetadataForm.siblingTextField(tf).isEmpty
    // *** Visible / Enable for Setting Buttons ***
    if !tf.isEmpty {
      metadataSettingButtons.isHidden = false
      metadataEditModeButton.isHidden = false

      if !isSiblingTfEmpty {
        metadataAddButton.isHidden = false
        metadataAddButton.isEnabled = true
      }
    } else {
      metadataAddButton.isEnabled = false
    }

    validateLabelDuplication()

    // *** Set style for metadataForm ***
    guard !currentMetadataForm.isDuplicated else { return } // if metadataForm is error cause duplication, keep as error
    if tf.isEmpty {
      currentMetadataForm.setStyle(state: isSiblingTfEmpty ? .focus : .error)
    } else if !isSiblingTfEmpty {
      currentMetadataForm.setStyle(state: .success)
    }
  }

  @objc func metadataFieldEditingDidEnd(_ tf: BoxTextField) {
    guard let currentMetadataForm = tf.parentView as? MetadataForm else { return }
    if currentMetadataForm.isBeginningState() {
      currentMetadataForm.setStyle(state: .default)
    }
  }

  @objc func setModeMetadataForm(_ sender: UIButton) {
    changeMetadataViewMode(isOnEdit: !metadataEditModeButton.isSelected)
  }

  @objc func propertyNameFieldEditingChanged(_ textfield: DesignedTextField) {
    if textfield.isEmpty {
      issueButton.isEnabled = false
      textfield.setStyle(state: .error)
    } else {
      issueButton.isEnabled = validToIssue()
      textfield.setStyle(state: .focus)
    }
  }

  @objc func tapToIssue(_ button: UIButton) {
    requireAuthenticationForAction(disposeBag) { [weak self] in
      self?._issue()
    }
  }

  fileprivate func _issue() {
    view.endEditing(true)

    guard let registrant = Global.currentAccount else { return }
    let quantity = Int(numberOfBitmarksTextField.value)

    showIndicatorAlert(message: "sendingTransaction".localized(tableName: "Message")) { (selfAlert) in
      self.createAssetObservable(registrant)
        .do(onNext: { [weak self] (assetId) in
          guard let self = self else { return }
          iCloudService.shared.localAssetWithFilenameData[assetId] = self.assetFileName
          try self.storeFileInAppStorage(of: assetId)
        })
        .map { (assetId) -> Void in
          try AssetService.issueBitmarks(issuer: registrant, assetId: assetId, quantity: quantity)
        }
        .subscribe(
          onNext: { (_) in
            selfAlert.dismiss(animated: true, completion: {
              Global.syncNewDataInStorage()

              self.showQuickMessageAlert(message: "successIssue".localized(tableName: "Message")) { [weak self] in
                self?.steps.accept(BitmarkStep.issueIsComplete)
              }
            })
          },
          onError: { (error) in
            selfAlert.dismiss(animated: true, completion: {
              self.showErrorAlert(message: "registerPropertyRights_unsuccessfully".localized(tableName: "Error"))
              ErrorReporting.report(error: error)
            })
          })
        .disposed(by: self.disposeBag)
    }
  }

  func createAssetObservable(_ registrant: Account) -> Observable<String> {
    if let assetR = assetRVariable.value {
      return Observable.just(assetR.id)
    } else {
      let assetName = propertyNameTextField.text!
      var metadata = extractMetadataFromForms()
      metadata["SOURCE"] = assetTypeTextField.text!

      return assetDataObservable.flatMap { (assetData) -> Observable<String> in
        let assetInfo = (
          registrant: registrant,
          assetName: assetName,
          fingerprint: assetData,
          metadata: metadata
        )
        let assetId = try AssetService.registerAsset(assetInfo: assetInfo)
        return Observable.just(assetId)
      }
    }
  }

  func storeFileInAppStorage(of assetId: String) throws {
    guard let assetURL = assetURL, let assetFileName = assetFileName else { return }
    ErrorReporting.breadcrumbs(info: "Path: \(assetURL.path); Filename: \(assetFileName)", category: .StoreFile, traceLog: true)
    ErrorReporting.breadcrumbs(info: assetId, category: .StoreFile, traceLog: true)

    try iCloudService.shared.storeFile(fileURL: assetURL, filename: assetFileName, assetId: assetId)
  }

  @objc func dismissKeyboard() {
    view.endEditing(true)
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    view.endEditing(true)
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == propertyNameTextField {
      textField.endEditing(true)
      showAssetTypePicker()
      return true
    }

    if let textfield = textField as? BoxTextField,
       let currentMetadataForm = textfield.parentView as? MetadataForm {

      guard IQKeyboardManager.shared.goNext() else {
        guard let currentIndex = metadataForms.firstIndex(of: currentMetadataForm) else { return true }
        let nextIndex = currentIndex + 1
        if nextIndex >= metadataForms.count {
          return currentMetadataForm.endEditing(true)
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
    guard metadataForms.count >= 1, let deleteMetadataForm = metadataForms.filter({ $0.uuid == uuid }).first else { return }

    if metadataForms.count == 1 {
      deleteMetadataForm.setStyle(state: .default)
      changeMetadataViewMode(isOnEdit: false)
      metadataSettingButtons.isHidden =  true
      metadataAddButton.isHidden = true
      metadataEditModeButton.isHidden = true
      deleteMetadataForm.labelTextField.becomeFirstResponder()
    } else {
      deleteMetadataForm.removeFromSuperview() // 1
      metadataForms.removeAll(deleteMetadataForm)
    }

    validateLabelDuplication() // 2
    validateButtons()  // 3
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
      errorForMetadata.text = "registerPropertyRights_duplicatedLabels".localized(tableName: "Error")

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

  func validToIssue() -> Bool {
    if assetRVariable.value == nil {
      return !propertyNameTextField.isEmpty &&
             !assetTypeTextField.isEmpty &&
              errorForMetadata.text?.isEmpty ?? true &&
              validMetadata() &&
              confirmCheckBox.on &&
              (networkReachabilityManager?.isReachable ?? false)
    } else {
      return confirmCheckBox.on &&
             (networkReachabilityManager?.isReachable ?? false)
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
    propertyNameTextField.addTarget(self, action: #selector(propertyNameFieldEditingChanged), for: .editingChanged)
    propertyNameTextField.addTarget(self, action: #selector(propertyNameFieldEditingChanged), for: .editingDidEnd)

    metadataAddButton.addTarget(self, action: #selector(tapToAddMetadataForm), for: .touchUpInside)
    metadataEditModeButton.addTarget(self, action: #selector(setModeMetadataForm), for: .touchUpInside)

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

    issueButton = SubmitButton(title: "Register".localized().localizedUppercase)

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
      propertyNameTextField, assetTypeTextField, metadataStackView, numberOfBitmarksBox
    ]
    inputFields.forEach({ (inputField) in
      inputField?.snp.makeConstraints { $0.width.equalTo(mainView) }
    })

    let recognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    recognizer.cancelsTouchesInView = true
    view.addGestureRecognizer(recognizer)

    setupDisabledScreen()
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
    let fieldLabel = CommonUI.inputFieldTitleLabel(text: "registerPropertyRights_assetFingerprintLabel".localized(tableName: "Phrase").localizedUppercase)

    assetFingerprintLabel = CommonUI.infoLabel(text: "")
    assetFingerprintLabel.textColor = .mainBlueColor

    let generatedFromLabel = UILabel()
    generatedFromLabel.text = "registerPropertyRights_generatedFromLabel".localized(tableName: "Phrase")
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
    let fieldLabel = CommonUI.inputFieldTitleLabel(text: "registerPropertyRights_propertyNameLabel".localized(tableName: "Phrase").localizedUppercase)
    propertyNameTextField = DesignedTextField(placeholder: "registerPropertyRights_64characterMax".localized(tableName: "Phrase"))
    propertyNameTextField.returnKeyType = .done

    return UIStackView(arrangedSubviews: [fieldLabel, propertyNameTextField], axis: .vertical, spacing: 15)
  }

  fileprivate func assetTypeView() -> UIStackView {
    let fieldLabel = CommonUI.inputFieldTitleLabel(text: "registerPropertyRights_assetTypeLabel".localized(tableName: "Phrase"))

    assetTypeTextField = BoxTextField(placeholder: "registerPropertyRights_selectAssetType".localized(tableName: "Phrase").localizedUppercase)
    assetTypeTextField.setStyle(state: .default)
    assetTypeTextField.isUserInteractionEnabled = false
    assetTypeTextField.rightView = getDownArrowAssetTypeSelectionView()
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
    let fieldLabel = CommonUI.inputFieldTitleLabel(
      text: "registerPropertyRights_propertyDescription".localized(tableName: "Phrase").localizedUppercase,
      isOptional: true
    )

    let fieldInfoLink = UIButton(type: .system)
    fieldInfoLink.contentHorizontalAlignment = .leading
    fieldInfoLink.setTitle("registerPropertyRights_whatIsPropertyDescription? >>".localized(tableName: "Phrase"), for: .normal)
    fieldInfoLink.setTitleColor(.mainBlueColor, for: .normal)
    fieldInfoLink.titleLabel?.font = UIFont(name: "Avenir", size: 13)
    fieldInfoLink.addTarget(self, action: #selector(goToPropertyDescriptionInfo), for: .touchUpInside)

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
      make.top.equalTo(fieldLabel.snp.bottom).offset(-6)
      make.leading.equalToSuperview()
    }

    separateLine.snp.makeConstraints { (make) in
      make.top.equalTo(fieldInfoLink.snp.bottom).offset(-8)
      make.leading.equalToSuperview()
      make.width.equalTo(fieldInfoLink.snp.width).offset(-20)
      make.height.equalTo(0.5)
    }

    metadataForms.snp.makeConstraints { (make) in
      make.top.equalTo(separateLine.snp.bottom).offset(18)
      make.leading.trailing.equalToSuperview()
    }

    errorForMetadataStackView.snp.makeConstraints { (make) in
      make.top.equalTo(metadataForms.snp.bottom)
      make.leading.trailing.bottom.equalToSuperview()
    }

    return view
  }

  fileprivate func numberOfBitmarksView() -> UIView {
    let fieldLabel = CommonUI.inputFieldTitleLabel(text: "registerPropertyRights_quantityLabel".localized(tableName: "Phrase"))
    numberOfBitmarksTextField = GMStepper()
    numberOfBitmarksTextField.minimumValue = 1
    numberOfBitmarksTextField.maximumValue = 100

    let flexBar = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let doneButton = UIBarButtonItem(title: "Done".localized(), style: .done, target: self, action: #selector(dismissKeyboard))
    let bar = UIToolbar()
    bar.sizeToFit()
    bar.items = [flexBar, doneButton]
    numberOfBitmarksTextField.textfield.inputAccessoryView = bar

    numberOfBitmarksBox = UIView()
    numberOfBitmarksBox.addSubview(fieldLabel)
    numberOfBitmarksBox.addSubview(numberOfBitmarksTextField)

    fieldLabel.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    numberOfBitmarksTextField.snp.makeConstraints { (make) in
      make.top.equalTo(fieldLabel.snp.bottom).offset(8)
      make.leading.bottom.equalToSuperview()
      make.height.equalTo(30)
      make.width.equalTo(171)
    }

    return numberOfBitmarksBox
  }

  fileprivate func ownershipClaimView() -> UIStackView {
    let fieldLabel = CommonUI.inputFieldTitleLabel(text: "registerPropertyRights_rightsClaimTitle".localized(tableName: "Phrase").localizedUppercase)
    confirmCheckBox = BEMCheckBox(frame: CGRect(x: 0, y: 0, width: 19, height: 19))
    confirmCheckBox.boxType = .square
    confirmCheckBox.onCheckColor = .white
    confirmCheckBox.onFillColor = .mainBlueColor
    confirmCheckBox.onTintColor = .mainBlueColor
    confirmCheckBox.animationDuration = 0.2
    confirmCheckBox.cornerRadius = 0

    let confirmCheckboxView = UIView()
    confirmCheckboxView.addSubview(confirmCheckBox)
    confirmCheckBox.snp.makeConstraints({ $0.top.equalToSuperview().offset(5) })

    let description = CommonUI.descriptionLabel(text: "registerPropertyRights_rightsClaimMessage".localized(tableName: "Phrase"))

    let confirmView = UIStackView(arrangedSubviews: [confirmCheckboxView, description], axis: .horizontal, spacing: 5, alignment: .fill, distribution: .fillProportionally)
    confirmCheckboxView.snp.makeConstraints({ $0.width.equalTo(19) })
    description.snp.makeConstraints({ $0.width.equalToSuperview().offset(-28) })

    return UIStackView(arrangedSubviews: [fieldLabel, confirmView], axis: .vertical, spacing: 10)
  }

  fileprivate func setupDisabledScreen() {
    disabledScreen = CommonUI.disabledScreen()
    activityIndicator = CommonUI.appActivityIndicator()

    guard let currentWindow: UIWindow = UIApplication.shared.keyWindow else { return }
    currentWindow.addSubview(disabledScreen)
    disabledScreen.addSubview(activityIndicator)

    disabledScreen.snp.makeConstraints { (make) in
      make.edges.equalToSuperview()
    }

    activityIndicator.snp.makeConstraints { (make) in
      make.centerX.centerY.equalToSuperview()
    }
  }

  fileprivate func setupMetadataAddButton() {
    metadataAddButton = UIButton(type: .system)
    metadataAddButton.titleLabel?.font = UIFont(name: Constant.andaleMono, size: 13)
    metadataAddButton.setImage(UIImage(named: "add_label")!.original, for: .normal)
    metadataAddButton.setImage(UIImage(named: "add_label_disabled")!.original, for: .disabled)
    metadataAddButton.setTitle("registerPropertyRights_addNewField".localized(tableName: "Phrase").localizedUppercase, for: .normal)
    metadataAddButton.setTitleColor(.mainBlueColor, for: .normal)
    metadataAddButton.setTitleColor(.silver, for: .disabled)
    metadataAddButton.centerTextAndImage(spacing: 8.0)
    metadataAddButton.contentHorizontalAlignment = .left
    metadataAddButton.imageView?.contentMode = .scaleAspectFit
  }

  fileprivate func setupMetadataEditModeButton() {
    metadataEditModeButton = UIButton()
    metadataEditModeButton.titleLabel?.font = UIFont(name: Constant.andaleMono, size: 13)
    metadataEditModeButton.setTitle("Edit".localized().localizedUppercase, for: .normal)
    metadataEditModeButton.setTitle("Done".localized().localizedUppercase, for: .selected)
    metadataEditModeButton.setTitleColor(.mainBlueColor, for: .normal)
    metadataEditModeButton.isHidden = true
  }

  fileprivate func getDownArrowAssetTypeSelectionView() -> UIView {
    downArrowAssetTypeSelection = UIButton()
    downArrowAssetTypeSelection.setImage(UIImage(named: "gray-arrow-down-tf"), for: .normal)
    downArrowAssetTypeSelection.setImage(UIImage(named: "arrow-down-tf"), for: .selected)

    let downArrowView = UIView()
    downArrowView.snp.makeConstraints { (make) in
      make.height.equalTo(20)
      make.width.equalTo(40)
    }
    downArrowView.addSubview(downArrowAssetTypeSelection)
    downArrowAssetTypeSelection.snp.makeConstraints { $0.edges.equalToSuperview() }
    return downArrowView
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
