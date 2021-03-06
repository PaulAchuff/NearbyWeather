//
//  OpenWeatherMapCityService.swift
//  NearbyWeather
//
//  Created by Erik Maximilian Martens on 07.01.18.
//  Copyright © 2018 Erik Maximilian Martens. All rights reserved.
//

import Foundation
import FMDB

final class WeatherStationService {
  
  // MARK: - Public Assets
  
  static var shared: WeatherStationService!
  
  // MARK: - Private Assets
  
  private lazy var openWeatherMapCityServiceBackgroundQueue: DispatchQueue = {
    return DispatchQueue(label: Constants.Labels.DispatchQueues.kOpenWeatherMapCityServiceBackgroundQueue,
                         qos: .userInitiated,
                         attributes: [.concurrent],
                         autoreleaseFrequency: .inherit,
                         target: nil)
  }()
  
  fileprivate let databaseQueue: FMDatabaseQueue
  
  // MARK: - Initialization
  
  private init() {
    let sqliteFilePath = R.file.locationsSQLiteSqlite()!.path // crash app if not found, cannot run without db
    self.databaseQueue = FMDatabaseQueue(path: sqliteFilePath)! // crash app if init fails, cannot run without db
  }
  
  // MARK: - Public Properties & Methods
  
  static func instantiateSharedInstance() {
    shared = WeatherStationService()
  }
  
  func locations(forSearchString searchString: String, completionHandler: @escaping (([WeatherStationDTO]?) -> Void)) {
    
    if searchString.isEmpty || searchString == "" { return completionHandler(nil) }
    
    openWeatherMapCityServiceBackgroundQueue.async {
      self.databaseQueue.inDatabase { database in
        let usedLocationIdentifiers: [String] = WeatherDataManager.shared.bookmarkedLocations.compactMap {
          return String($0.identifier)
        }
        let sqlUsedLocationsIdentifierssArray = "('" + usedLocationIdentifiers.joined(separator: "','") + "')"
        let query = !usedLocationIdentifiers.isEmpty ? "SELECT * FROM locations l WHERE l.id NOT IN \(sqlUsedLocationsIdentifierssArray) AND (lower(name) LIKE '%\(searchString.lowercased())%') ORDER BY country, l.name" : "SELECT * FROM locations l WHERE (lower(name) LIKE '%\(searchString.lowercased())%') ORDER BY l.name, l.country"
        var queryResult: FMResultSet?
        
        do {
          queryResult = try database.executeQuery(query, values: nil)
        } catch {
          printDebugMessage(domain: String(describing: self),
                            message: error.localizedDescription)
          return completionHandler(nil)
        }
        
        guard let result = queryResult else {
          completionHandler(nil)
          return
        }
        
        var retrievedLocations = [WeatherStationDTO]()
        while result.next() {
          guard let location = WeatherStationDTO(from: result) else {
            return
          }
          retrievedLocations.append(location)
        }
        
        guard !retrievedLocations.isEmpty else {
          return completionHandler(nil)
        }
        completionHandler(retrievedLocations)
      }
    }
  }
}
