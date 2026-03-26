//
//  ContentView.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/26/26.
//

import SwiftUI

struct GamesListView: View {
  
  @StateObject var viewModel: GamesListViewModel
  
  var body: some View {
    VStack {
      List(viewModel.games) { game in
        Text(game.name)
        //      NavigationLink(destination: GameDetailView(viewModel: .init(game: game))) {
        //        GameListItemView(viewModel: .init(game: game))
        //      }
      }
    }
    .task {
      await viewModel.getGames(searchString: "Halo")
    }
  }
}

#Preview {
  GamesListView(viewModel: GamesListViewModel(container: .preview))
}
