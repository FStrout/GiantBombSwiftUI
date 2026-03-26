//
//  GamesListViewModel.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/26/26.
//

import Combine
import Foundation

@MainActor
final class GamesListViewModel: ObservableObject {
  @Published var games: [Game] = []
  
  // MARK: - Dependencies
  
  private let gameRepository: GameRepositoryProtocol
  
  init(container: DIContainer) {
    self.gameRepository = container.gameRepository
  }
  
  func getGames(searchString: String) async {
    do {
      self.games = try await self.gameRepository.getGame(searchString: searchString)
    } catch {
      print(error.localizedDescription)
    }
  }
}
