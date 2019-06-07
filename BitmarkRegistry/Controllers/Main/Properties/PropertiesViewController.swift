//
//  PropertiesViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/31/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit
import BitmarkSDK

class PropertiesViewController: UIViewController {

  // MARK: - Properties
  @IBOutlet weak var segmentControl: UISegmentedControl!
  @IBOutlet weak var yoursSegment: UIView!
  @IBOutlet weak var trackedSegment: UIView!
  @IBOutlet weak var globalSegment: UIView!
  @IBOutlet weak var yoursTableView: UITableView!
  @IBOutlet weak var emptyBoxInYoursTab: UIView!

  var bitmarks = [Bitmark]()
  let yoursTableIdentifier = "yoursTableIdentifier"
  lazy var bitmarkStorage: BitmarkStorage = {
    return BitmarkStorage(for: Global.currentAccount!)
  }()
  let bitmarkDetailSegue = "bitmarkDetailSegue"
  var observers = NSPointerArray.weakObjects()

  override func viewDidLoad() {
    super.viewDidLoad()
    loadData()
//    try! bitmarkStorage.getLatestSize()
  }

  // MARK: - Data Handlers
  private func loadData() {
    var errorMessage: String? = nil
    let alert = showAlertWithIndicator(message: "Syncing Bitmarks") {
      do {
        try self.bitmarkStorage.sync()
        self.bitmarks = try self.bitmarkStorage.getBitmarkData()

        if self.bitmarks.count > 0 {
          self.yoursTableView.reloadData()
          self.emptyBoxInYoursTab.isHidden = true
        } else {
          self.emptyBoxInYoursTab.isHidden = false
        }
        print("-----------------------LOG THUYEN bitmark count_____________________")
        print(self.bitmarks.count)

      } catch let e {
        errorMessage = e.localizedDescription
      }
    }

    // show result alert
    alert.dismiss(animated: true) {
      if let errorMessage = errorMessage { self.showErrorAlert(message: errorMessage) }
    }
  }

  // MARK: - Handlers
  @IBAction func propertySegmentTapped(_ sender: UISegmentedControl) {
    let selectedPropertySegment = PropertySegment(rawValue: sender.selectedSegmentIndex)!
    switch selectedPropertySegment {
    case .Yours:
      yoursSegment.isHidden = false
      trackedSegment.isHidden = true
      globalSegment.isHidden = true
    case .Tracked:
      yoursSegment.isHidden = true
      trackedSegment.isHidden = false
      globalSegment.isHidden = true
    case .Global:
      yoursSegment.isHidden = true
      trackedSegment.isHidden = true
      globalSegment.isHidden = false
    }
  }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension PropertiesViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return bitmarks.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: yoursTableIdentifier, for: indexPath) as! YourPropertyCell
    let bitmark = bitmarks[indexPath.row]
    let asset = Global.findAsset(with: bitmark.asset_id)
    cell.loadWith(asset, bitmark)
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    performSegue(withIdentifier: bitmarkDetailSegue, sender: indexPath)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == bitmarkDetailSegue,
       let destination = segue.destination as? BitmarkDetailViewController,
       let sender = sender as? IndexPath {
      destination.bitmark = bitmarks[sender.row]
    }
  }
}
