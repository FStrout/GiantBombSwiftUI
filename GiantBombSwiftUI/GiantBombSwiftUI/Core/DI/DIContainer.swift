//
//  DIContainer.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/26/26.
//

import Combine
import Foundation
import SwiftData

@MainActor
final class DIContainer: ObservableObject {
  
  nonisolated let objectWillChange = ObservableObjectPublisher()
  
  // MARK: - Shared Instance
  
  static let shared = DIContainer()
  
  // MARK: - Services (lazily initialised)
  
  let apiService: APIServiceProtocol
  
  // MARK: - Repositories
  
  lazy var gameRepository: GameRepositoryProtocol = GameRepository(
    apiService: apiService
  )
  
  // MARK: - Designated Init
  
  init(apiService: APIServiceProtocol) {
    self.apiService = apiService
  }
  
  // MARK: - Init (production)
  
  convenience init() {
    let api = APIService()
    if !AppConfiguration.apiKey.isEmpty {
      api.setGlobalHeader(value: AppConfiguration.apiKey, forKey: "X-API-Key")
    }
    
    self.init(apiService: api)
  }
  
  // MARK: - Init (unit tests / previews)
  
  #if DEBUG
  /// Creates a container where all services are replaced with mocks,
  /// and the database is in-memory only.
  convenience init(testing: Bool) {
    guard testing else {
      self.init()
      return
    }
    
    self.init(apiService: MockAPIService())
  }
  
  static var preview: DIContainer { DIContainer(testing: true) }
  #endif
}
