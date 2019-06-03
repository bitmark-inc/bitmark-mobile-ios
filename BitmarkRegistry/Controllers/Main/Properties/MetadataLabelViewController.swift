//
//  MetaDataLabelViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/2/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

protocol MetadataLabelUpdationDelegate {
  func updateMetadataLabel(_ label: String)
}

class MetadataLabelViewController: UIViewController {

  // MARK: - Properties
  @IBOutlet weak var labelTextField: UITextField!
  @IBOutlet weak var suggestedLabelTableView: UITableView!

  var metadataLabel: String!
  var delegate: MetadataLabelUpdationDelegate?

  let defaultTitle = "LABEL 1"
  let defaultSuggestedLabels = ["date created", "contributor", "coverage", "creator",
                                 "description", "dimensions", "duration", "edition",
                                 "format", "identifier", "language", "license",
                                 "medium", "publisher", "relation", "rights",
                                 "size", "source", "subject", "keywords",
                                 "type", "version"]
  var suggestedLabels = [String]()
  let suggestedLabelReuseIdentifier = "suggestedLabelReuseIdentifier"
  var labelTag = 1

  override func viewDidLoad() {
    title = metadataLabel == "" ? defaultTitle : metadataLabel
    configureUI()
    loadData()
  }

  private func loadData() {
    suggestedLabels = defaultSuggestedLabels
    labelTextField.text = metadataLabel
    labelTextField.sendActions(for: .editingChanged) // for default filter
  }

  @IBAction func clickDone(_ sender: Any) {
    doneUpdate(with: labelTextField.text!.uppercased())
  }

  @IBAction func filterSuggestedLabels(_ textfield: UITextField) {
    if let filterText = textfield.text, filterText != "" {
      suggestedLabels = defaultSuggestedLabels.filter({ $0.contains(filterText.lowercased()) })
    } else {
      suggestedLabels = defaultSuggestedLabels
    }
    suggestedLabelTableView.reloadData()
  }

  private func doneUpdate(with label: String) {
    delegate?.updateMetadataLabel(label)
    navigationController?.popViewController(animated: true)
  }
}

// MARK: - UITableViewDataSource
extension MetadataLabelViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return suggestedLabels.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: suggestedLabelReuseIdentifier, for: indexPath)
    cell.selectionStyle = .none
    if let label = cell.viewWithTag(1) as? UILabel {
      label.text = suggestedLabels[indexPath.row].uppercased()
    }
    return cell
  }
}

// MARK: - UITableViewDelegate
extension MetadataLabelViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let cell = tableView.cellForRow(at: indexPath)
    let selectedSuggestedLabel = cell?.viewWithTag(1) as! UILabel
    doneUpdate(with: selectedSuggestedLabel.text!)
  }
}

// MARK: - Configure UI
extension MetadataLabelViewController {
  func configureUI() {
    suggestedLabelTableView.contentInset = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 0)
    suggestedLabelTableView.separatorStyle = .none
  }
}
