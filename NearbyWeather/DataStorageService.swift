//
//  DataStorageService.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 08.01.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import Foundation

enum StorageLocationType {
  case bundle
  case documents
  case applicationSupport
}

class DataStorageService {    
  
  // MARK: - Public Functions
  
  static func storeJson<T: Encodable>(for codable: T, inFileWithName fileName: String, toStorageLocation location: StorageLocationType) {
    guard let destinationDirectoryURL = directoryURL(for: location) else {
      print("💥 DataStorageService: Could not construct directory url.")
      return
    }
    if !FileManager.default.fileExists(atPath: destinationDirectoryURL.path, isDirectory: nil) {
      do {
        try FileManager.default.createDirectory(at: destinationDirectoryURL, withIntermediateDirectories: true, attributes: nil)
      } catch {
        print("💥 DataStorageService: Error while creating directory \(destinationDirectoryURL.path). Error-Description: \(error.localizedDescription)")
        return
      }
    }
    let fileExtension = "json"
    let filePathUrl = destinationDirectoryURL.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
    
    do {
      let data = try JSONEncoder().encode(codable)
      try data.write(to: filePathUrl)
    } catch let error {
      print("💥 DataStorageService: Error while writing data to \(filePathUrl.path). Error-Description: \(error.localizedDescription)")
    }
  }
  
  static func retrieveJsonFromFile<T: Decodable>(with fileName: String, andDecodeAsType type: T.Type, fromStorageLocation location: StorageLocationType) -> T? {
    guard let fileBaseURL = directoryURL(for: location, fileName: fileName, fileExtension: "json") else {
      print("💥 DataStorageService: Could not construct directory url.")
      return nil
    }
    let fileExtension = "json"
    let filePathUrl = fileBaseURL.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
    
    if !FileManager.default.fileExists(atPath: filePathUrl.path) {
      print("💥 DataStorageService: File at path \(filePathUrl.path) does not exist!")
      return nil
    }
    do {
      let data = try Data(contentsOf: filePathUrl)
      let model = try JSONDecoder().decode(type, from: data)
      return model
    } catch let error {
      print("💥 DataStorageService: Error while retrieving data from \(filePathUrl.path). Error-Description: \(error.localizedDescription)")
      return nil
    }
  }
  
  // MARK: - Private Functions
  
  static private func directoryURL(for location: StorageLocationType, fileName: String? = nil, fileExtension: String? = nil) -> URL? {
    switch location {
    case .bundle:
      return Bundle.main.bundleURL
    case .documents:
      return  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    case .applicationSupport:
      return  FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
    }
  }
}
