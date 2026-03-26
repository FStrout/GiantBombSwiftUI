//
//  Game.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/26/26.
//

import Foundation
import SwiftUI

class Game: Codable {
  var id: Int64 = 0
  var name: String = ""
  var images = [String: String]()
  var image = Image(systemName: "globe")
  
  enum CodingKeys: String, CodingKey {
    case id = "id"
    case name = "name"
    case images = "image"
  }
  
  required convenience init(from decoder: Decoder) throws {
    self.init()
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(Int64.self, forKey: .id)
    self.name = try container.decode(String.self, forKey: .name)
    self.images = try container.decode([String:String].self, forKey: .images)
  }
  
}
