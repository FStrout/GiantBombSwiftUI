//
//  GameResult.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/26/26.
//

import Foundation

struct GameResult: Codable {
  let results: [Game]
}

#if DEBUG
extension GameResult {
  static let preview: [Game] = []
}
#endif
