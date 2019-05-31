//
//  PropertiesViewController.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 5/31/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import UIKit

class PropertiesViewController: UIViewController {

  // MARK: - Properties
  @IBOutlet weak var segmentControl: UISegmentedControl!
  @IBOutlet weak var yoursSegment: UIView!
  @IBOutlet weak var trackedSegment: UIView!
  @IBOutlet weak var globalSegment: UIView!

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
