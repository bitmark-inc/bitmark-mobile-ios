//
//  MetadataLabelViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/12/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

protocol MetadataLabelUpdationDelegate {
  func updateMetadataLabel(_ label: String)
}

class MetadataLabelViewController: UIViewController, UITextFieldDelegate {

  // MARK: - Properties
  let defaultTitle = "LABEL 1"
  let defaultSuggestedLabels = ["date created", "contributor", "coverage", "creator",
                                "description", "dimensions", "duration", "edition",
                                "format", "identifier", "language", "license",
                                "medium", "publisher", "relation", "rights",
                                "size", "source", "subject", "keywords",
                                "type", "version"]
  var suggestedLabels = [String]()
  var metadataLabel: String!
  var delegate: MetadataLabelUpdationDelegate?

  var labelTextField: DesignedTextField!
  var suggestedLabelTableView: UITableView!
  var recognizer: UITapGestureRecognizer!

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = metadataLabel.isEmpty ? defaultTitle : metadataLabel
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneUpdate))
    setupViews()
    setupEvents()

    loadData()
  }

  // MARK: - Data Handlers
  private func loadData() {
    suggestedLabels = defaultSuggestedLabels
    labelTextField.text = metadataLabel
    labelTextField.sendActions(for: .editingChanged) // for default filter
  }

  // MARK: - Handlers
  @objc func filterSuggestedLabels(_ textfield: UITextField) {
    if textfield.isEmpty {
      suggestedLabels = defaultSuggestedLabels
      textfield.rightViewMode = .never
    } else {
      suggestedLabels = defaultSuggestedLabels.filter({ $0.contains(textfield.text!.lowercased()) })
      textfield.rightViewMode = .always
    }
    suggestedLabelTableView.reloadData()
  }

  @objc func beginEditing(_ textfield: UITextField) {
    recognizer.isEnabled = true
  }

  @objc func dismissKeyboard() {
    recognizer.isEnabled = false
    view.endEditing(true)
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    dismissKeyboard()
    return true
  }

  @objc func doneUpdate() {
    delegate?.updateMetadataLabel(labelTextField.text!)
    navigationController?.popViewController(animated: true)
  }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension MetadataLabelViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return suggestedLabels.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withClass: LabelCell.self, for: indexPath)
    cell.label.text = suggestedLabels[indexPath.row].uppercased()
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath) as! LabelCell
    labelTextField.text = cell.label.text
    doneUpdate()
  }
}

// MARK: - Setup Views/Events
extension MetadataLabelViewController {
  fileprivate func setupEvents() {
    labelTextField.delegate = self
    suggestedLabelTableView.delegate = self

    labelTextField.addTarget(self, action: #selector(beginEditing), for: .editingDidBegin)
    labelTextField.addTarget(self, action: #selector(filterSuggestedLabels), for: .editingChanged)
  }

  fileprivate func setupViews() {
    view.backgroundColor = .white

    // *** Setup subviews ***
    labelTextField = DesignedTextField(placeholder: "SELECT OR CREATE A LABEL")
    labelTextField.returnKeyType = .done

    suggestedLabelTableView = UITableView()
    suggestedLabelTableView.register(cellWithClass: LabelCell.self)
    suggestedLabelTableView.dataSource = self
    suggestedLabelTableView.separatorStyle = .none

    // *** Setup UI in view ***
    let mainView = UIView()
    mainView.addSubview(labelTextField)
    mainView.addSubview(suggestedLabelTableView)

    labelTextField.snp.makeConstraints { (make) in
      make.top.leading.trailing.equalToSuperview()
    }

    suggestedLabelTableView.snp.makeConstraints { (make) in
      make.top.equalTo(labelTextField.snp.bottom).offset(25)
      make.leading.trailing.bottom.equalToSuperview()
    }

    view.addSubview(mainView)
    mainView.snp.makeConstraints { (make) in
      make.edges.equalTo(view.safeAreaLayoutGuide)
          .inset(UIEdgeInsets(top: 25, left: 20, bottom: 20, right: 25))
    }

    recognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
    recognizer.isEnabled = false
    view.addGestureRecognizer(recognizer)
  }
}
