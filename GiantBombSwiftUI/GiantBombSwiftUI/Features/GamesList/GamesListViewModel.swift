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
  @Published var foods: [Food] = [] {
    didSet {
      foods.isEmpty ? (viewState = .empty) : (viewState = .list)
    }
  }
  var viewState: ViewState = .empty
  
  // MARK: - Dependencies
  
  private let usdaRepository: UsdaRepositoryProtocol
  private let gameRepository: GameRepositoryProtocol
  
  init(container: DIContainer) {
    self.usdaRepository = container.usdaRepository
    self.gameRepository = container.gameRepository
  }
  
  func getFoods(searchString: String) {
    viewState = .loading
    if !foods.isEmpty {
      foods.removeAll()
    }
    
    Task {
      do {
        self.foods = try await self.usdaRepository.getFoods(searchString: searchString)
      } catch {
        print(error.localizedDescription)
      }
    }
  }
  
  func getFoods(searchString: String) async {
    do {
      self.foods = try await self.usdaRepository.getFoods(searchString: searchString)
    } catch {
      print(error.localizedDescription)
    }
  }
  
  func getGames(searchString: String) async {
    do {
      self.games = try await self.gameRepository.getGame(searchString: searchString)
    } catch {
      print(error.localizedDescription)
    }
  }
  
  enum ViewState {
    case empty
    case list
    case loading
  }
}
