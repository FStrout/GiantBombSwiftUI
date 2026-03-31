//
//  UsdaRepository.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/31/26.
//

import Foundation

// MARK: - Protocol

protocol UsdaRepositoryProtocol {
  /// Fetches a game from the API.
  func getFoods(searchString: String) async throws -> [Food]
  
  /// Clears all locally cached users (e.g. on sign-out).
  func clearCache() throws
}

// MARK: - Concrete Implementation

final class UsdaRepository: UsdaRepositoryProtocol {
  
  // MARK: - Dependencies
  
  private let apiService: APIServiceProtocol
  
  // MARK: - Init
  
  init(apiService: APIServiceProtocol) {
    self.apiService = apiService
  }
  
  // MARK: - FoodRepositoryProtocol
  func getFoods(searchString: String) async throws -> [Food] {
    let response: FoodSearchResponse = try await apiService.request(UsdaEndpoint.getFoods(searchString: searchString))
    return response.foods
  }
  
  func clearCache() throws {
    // Clear local cache
  }
}

// MARK: - Mock Implementation (for unit tests & SwiftUI previews)

#if DEBUG
final class MockUsdaRepository: UsdaRepositoryProtocol {
  
  var stubbedError: Error?
  var stubbedFoods: [Food]?
  
  private(set) var searchString: String?
  private(set) var clearCacheCalled = false
  
  func getFoods(searchString: String) async throws -> [Food] {
    self.searchString = searchString
    if let error = stubbedError { throw error }
    return stubbedFoods ?? FoodSearchResponse.preview
  }
  
  func clearCache() throws {
    clearCacheCalled = true
  }
}
#endif
