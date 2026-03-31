//
//  Food.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/31/26.
//

import Foundation

struct Food: Codable, Identifiable {
  let fdcId: Int
  let dataType: String
  let description: String
  let foodCode: Int?
  let foodNutrients: [FoodNutrient]?
  let publicationDate: String?
  let scientificName: String?
  let brandOwner: String?
  let gtinUpc: String?
  let ingredients: String?
  let ndbNumber: Int?
  let additionalDescriptions: String?
  let allHighlightFields: String?
  let score: Double?
  
  var id: Int { fdcId }
}

struct FoodNutrient: Codable {
  let number: Int?
  let name: String?
  let amount: Double?
  let unitName: String?
  let derivationCode: String?
  let derivationDescription: String?
}
