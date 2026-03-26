//
//  GameResult.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/26/26.
//

import Foundation

class GameResult: Codable {
  var error = ""
  var limit: Int64 = 0
  var offset: Int64 = 0
  var results = [Game]()
  
  enum CodingKeys: String, CodingKey {
    case error = "error"
    case limit = "limit"
    case offset = "offset"
    case results = "results"
  }
  
  required convenience init(from decoder: Decoder) throws {
    self.init()
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.error = try container.decode(String.self, forKey: .error)
    self.limit = try container.decode(Int64.self, forKey: .limit)
    self.offset = try container.decode(Int64.self, forKey: .offset)
    self.results = try container.decode([Game].self, forKey: .results)
  }
}

#if DEBUG
extension GameResult {
  static let preview = GameResult().results
}
#endif
