//
//  BitmarkDetailViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/5/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK

class BitmarkDetailViewController: UIViewController {

  // MARK: - Properties
  @IBOutlet weak var assetNameLabel: UILabel!
  @IBOutlet weak var issueDateLabel: UILabel!
  @IBOutlet weak var issuerLabel: UILabel!
  @IBOutlet weak var metadataTableView: UITableView!
  @IBOutlet weak var metadataTableViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var transactionTableView: UITableView!
  @IBOutlet weak var transactionIndicator: UIActivityIndicatorView!

  @IBOutlet weak var actionsMenuView: UIView!
  @IBOutlet weak var copiedToClipboardNotifier: UILabel!

  var bitmark: Bitmark!
  lazy var asset: Asset = {
    return Global.findAsset(with: bitmark.asset_id)!
  }()

  let metadataCellIdentifier = "metadataCellIdentifier"
  let metadataCellHeight: CGFloat = 30
  var metadatas: [String: String]! {
    didSet {
      metadataObjects.removeAll()
      for (key, value) in metadatas {
        metadataObjects.append(metadataObject(label: key, description: value))
      }
    }
  }
  var metadataObjects = [metadataObject]()

  let transactionCellIdentifier = "transactionCellIdentifier"
  var transactions = [Transaction]()

  let transferSegue = "transferSegue"

  // MARK: - Init
  override func viewDidLoad() {
    super.viewDidLoad()

    title = asset.name

    loadData()
    configureUI()
    loadTransactions()
  }

  // MARK: - Data Handlers
  private func loadData() {
    assetNameLabel.text = asset.name
    metadatas = asset.metadata
    issueDateLabel.text = bitmark.created_at?.format()
    issuerLabel.text = bitmark.issuer.middleShorten()
  }

  // MARK: - Actions Menu Handlers
  @IBAction func toggleActionsMenu(sender: UIBarButtonItem) {
    actionsMenuView.isHidden = !actionsMenuView.isHidden
    sender.image = UIImage(named: actionsMenuView.isHidden ? "More Actions-close" : "More Actions-open") 
  }

  @IBAction func touchToCopyId(button: UIButton) {
    UIPasteboard.general.string = bitmark.id
    copiedToClipboardNotifier.showIn(period: 1.2)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == transferSegue, let destination = segue.destination as? TransferBitmarkViewController {
      destination.bitmarkId = bitmark.id
      destination.assetName = asset.name
    }
  }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension BitmarkDetailViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tableView == metadataTableView
              ? metadataObjects.count
              : transactions.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if tableView == metadataTableView {
      let cell = tableView.dequeueReusableCell(withIdentifier: metadataCellIdentifier, for: indexPath) as! MetadataShowCell
      let metadata = metadataObjects[indexPath.row]
      cell.setData(label: metadata.label, description: metadata.description)
      return cell
    } else {
      let cell = tableView.dequeueReusableCell(withIdentifier: transactionCellIdentifier, for: indexPath) as! TransactionCell
      let transaction = transactions[indexPath.row]
      // TODO: Set Date() for now cause transaction data hasn't had timestamp yet
      cell.setData(timestamp: Date(), owner: transaction.owner)
      return cell
    }
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return tableView == transactionTableView ? 20.0 : 0.0
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return tableView == transactionTableView
            ? provenanceTableViewHeader(tableView)
            : nil
  }
}

// MARK: - Load transactions
extension BitmarkDetailViewController {
  private func loadTransactions() {
    transactionIndicator.startAnimating()
    TransactionService.listAllTransactions(of: bitmark.id) { [weak self] (transactions, error) in
      guard let self = self else { return }
      guard error == nil else {
        self.showErrorAlert(message: error!.localizedDescription)
        return
      }

      self.transactions = transactions!
      DispatchQueue.main.async {
        self.transactionIndicator.stopAnimating()
        self.transactionTableView.reloadData()
      }
    }
  }
}

// MARK: - Configure UI
extension BitmarkDetailViewController {
  private func configureUI() {
    metadataTableViewHeightConstraint.constant = CGFloat(metadataObjects.count) * metadataCellHeight

    // set up shadow for actionsMenuView
    actionsMenuView.layer.masksToBounds = false
    actionsMenuView.layer.shadowColor = UIColor.black.cgColor
    actionsMenuView.layer.shadowOpacity = 0.2
    actionsMenuView.layer.shadowOffset = .zero
    actionsMenuView.layer.shadowRadius = 1
  }

  // layout header of provenance - transactions table view
  func provenanceTableViewHeader(_ tableView: UITableView) -> UIView {
    let view = UIView()
    let timestampLabel = UILabel(); timestampLabel.text = "TIMESTAMP"
    timestampLabel.textColor = .black
    timestampLabel.font = UIFont(name: "Courier", size: 13)

    let ownerLabel = UILabel(); ownerLabel.text = "OWNER"
    ownerLabel.textColor = .black
    ownerLabel.font = UIFont(name: "Courier", size: 13)

    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.distribution = .fillProportionally
    stackView.alignment = .fill
    stackView.addArrangedSubview(timestampLabel)
    stackView.addArrangedSubview(ownerLabel)
    stackView.arrangedSubviews[0].widthAnchor.constraint(equalTo: stackView.arrangedSubviews[1].widthAnchor, multiplier: 1.3).isActive = true

    view.addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

    view.backgroundColor = .mainLightGrayColor
    return view
  }
}
