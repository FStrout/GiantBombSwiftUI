//
//  Game.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/26/26.
//

import Foundation
import SwiftUI

struct Game: Codable, Identifiable {
  let id: Int
  let name: String
  let image: String?
  
  enum CodingKeys: String, CodingKey {
    case id
    case name
    case image
  }
}
