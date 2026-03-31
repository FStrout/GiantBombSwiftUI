//
//  FoodSearchResponse.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/31/26.
//

import Foundation

// MARK: - Root

struct FoodSearchResponse: Codable {
  let foodSearchCriteria: FoodSearchCriteria
  let totalHits: Int
  let currentPage: Int
  let totalPages: Int
  let foods: [Food]
}

// MARK: - FoodSearchCriteria
struct FoodSearchCriteria: Codable {
  let query: String
  let dataType: [String]?
  let pageSize: Int?
  let pageNumber: Int?
  let sortBy: String?
  let sortOrder: String?
  let brandOwner: String?
  let tradeChannel: [String]?
  let startDate: String?
  let endDate: String?
}

#if DEBUG
extension FoodSearchResponse {
  static let preview: [Food] = []
}
#endif
