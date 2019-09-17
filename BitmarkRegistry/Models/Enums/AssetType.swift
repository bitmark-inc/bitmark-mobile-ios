//
//  AssetType.swift
//  BitmarkRegistry
//
//  Created by Thuyen Truong on 7/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import MobileCoreServices

enum AssetType: String {
  case medical
  case health
  case image
  case video
  case doc
  case zip
  case unknown

  func thumbnailImage() -> UIImage? {
    switch self {
    case .medical:
      return UIImage(named: "medical-record-asset-type")
    case .health:
      return UIImage(named: "health-data-asset-type")
    case .image:
      return UIImage(named: "image-asset-type")
    case .video:
      return UIImage(named: "video-asset-type")
    case .doc:
      return UIImage(named: "doc-asset-type")
    case .zip:
      return UIImage(named: "zip-asset-type")
    case .unknown:
      return UIImage(named: "unknown-asset-type")
    }
  }

  static func get(from assetR: AssetR) -> AssetType {
    if !assetR.metadata.isEmpty,
       let sourceMetadata = assetR.metadata.first(where: { $0.key.caseInsensitiveCompare("source") == .orderedSame }),
       let assetType = AssetType.get(fromSource: sourceMetadata.value) {
      return assetType
    }

    if let assetFilename = assetR.filename {
      return AssetType.get(fromFilename: assetFilename)
    }

    return .unknown
  }

  static func get(fromSource source: String) -> AssetType? {
    switch source {
    case "Health Records", "Medical Records":
      return .medical
    case "Health Kit", "Health":
      return .health
    default:
      return nil
    }
  }

  fileprivate static func get(fromFilename filename: String) -> AssetType {
    let pathExtension: CFString = filename.pathExtension as CFString
    guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, nil)?.takeRetainedValue() else { return .unknown }

    for imageType in FileType.imageTypes {
      if UTTypeConformsTo(uti, imageType) { return .image }
    }

    for videoType in FileType.videoTypes {
      if UTTypeConformsTo(uti, videoType) { return .video }
    }

    for docType in FileType.docTypes {
      if UTTypeConformsTo(uti, docType) { return .doc }
    }

    for zipType in FileType.zipTypes {
      if UTTypeConformsTo(uti, zipType) { return .zip }
    }

    return .unknown
  }
}

struct FileType {
  static let imageTypes = [
    kUTTypeImage, kUTTypeJPEG, kUTTypeJPEG2000, kUTTypeTIFF, kUTTypePICT, kUTTypeGIF, kUTTypePNG,
    kUTTypeQuickTimeImage, kUTTypeAppleICNS,
    kUTTypeBMP, kUTTypeICO, kUTTypeRawImage, kUTTypeScalableVectorGraphics, kUTTypeLivePhoto
  ]

  static let videoTypes = [
    kUTTypeAudiovisualContent, kUTTypeMovie, kUTTypeVideo, kUTTypeAudio, kUTTypeQuickTimeMovie, kUTTypeMPEG, kUTTypeMPEG2Video,
    kUTTypeMPEG2TransportStream, kUTTypeMP3, kUTTypeMPEG4, kUTTypeMPEG4Audio, kUTTypeAppleProtectedMPEG4Audio, kUTTypeAppleProtectedMPEG4Video,
    kUTTypeAVIMovie, kUTTypeAudioInterchangeFileFormat, kUTTypeWaveformAudio, kUTTypeMIDIAudio, kUTTypePlaylist, kUTTypeM3UPlaylist
  ]

  static let docTypes = [
    kUTTypeXML, kUTTypeJSON, kUTTypePropertyList, kUTTypeXMLPropertyList, kUTTypeBinaryPropertyList,
    kUTTypePDF, kUTTypeSpreadsheet, kUTTypePresentation, kUTTypeDatabase
  ]

  static let zipTypes = [
    kUTTypeGNUZipArchive, kUTTypeBzip2Archive, kUTTypeZipArchive
  ]
}
