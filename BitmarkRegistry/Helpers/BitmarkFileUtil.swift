//
//  FileUtil.swift
//  BitmarkRegistry
//
//  Created by Macintosh on 6/28/19.
//  Copyright © 2019 thuyentruong. All rights reserved.
//

import Foundation

class BitmarkFileUtil {
  static func moveFile(from fileURL: URL, toFolder downloadedFolderURL: URL) throws {
    let filename = fileURL.lastPathComponent
    let destinationURL = downloadedFolderURL.appendingPathComponent(filename)
    let data = try Data(contentsOf: fileURL)
    try data.write(to: destinationURL, options: [.completeFileProtection, .atomic])
  }
}
