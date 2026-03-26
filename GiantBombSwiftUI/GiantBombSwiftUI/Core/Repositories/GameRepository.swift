//
//  GameRepository.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/26/26.
//

import Foundation

// MARK: - Protocol

protocol GameRepositoryProtocol {
  /// Fetches a game from the API.
  func getGame(searchString: String) async throws -> [Game]
  
  /// Clears all locally cached users (e.g. on sign-out).
  func clearCache() throws
}

// MARK: - Concrete Implementation

final class GameRepository: GameRepositoryProtocol {
  
  // MARK: - Dependencies
  
  private let apiService: APIServiceProtocol
  
  // MARK: - Init
  
  init(apiService: APIServiceProtocol) {
    self.apiService = apiService
  }
  
  // MARK: - GameRepositoryProtocol
  func getGame(searchString: String) async throws -> [Game] {
    let response: GameResult = try await apiService.request(GameEndpoint.getGame(searchString: searchString))
    return response.results
  }
  
  func clearCache() throws {
    // Clear local cache
  }
}

// MARK: - Mock Implementation (for unit tests & SwiftUI previews)

#if DEBUG
final class MockUserRepository: GameRepositoryProtocol {
  
  var stubbedError: Error?
  var stubbedGames: [Game]?
  
  private(set) var searchString: String?
  private(set) var clearCacheCalled = false
  
  func getGame(searchString: String) async throws -> [Game] {
    self.searchString = searchString
    if let error = stubbedError { throw error }
    return stubbedGames ?? GameResult.preview
  }
  
  func clearCache() throws {
    clearCacheCalled = true
  }
}
#endif
