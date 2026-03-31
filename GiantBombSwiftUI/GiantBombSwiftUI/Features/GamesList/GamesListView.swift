//
//  ContentView.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/26/26.
//

import SwiftUI

struct GamesListView: View {
  
  @StateObject var viewModel: GamesListViewModel
  @State var searchString: String = ""
  
  var body: some View {
    ZStack {
      
      switch viewModel.viewState {
      case .empty:
        emptyView
      case .list:
        listView
      case .loading:
        loadingView
      }
      
      VStack {
        Spacer()
        HStack {
          TextField(text: $searchString) {
            Text("Search")
          }
          Button {
            viewModel.getFoods(searchString: searchString)
          } label: {
            Image(systemName: "magnifyingglass")
          }
        }
        .padding()
        .background(Color.white)
        .padding([.top, .horizontal])
      }
//      .task {
//        await viewModel.getFoods(searchString: "Tuna")
//        //      await viewModel.getGames(searchString: "Halo")
//      }
    }
  }
  
  var emptyView: some View {
    Text("No Items Found")
  }
  
  var listView: some View {
    VStack {
      List(viewModel.foods) { food in
        Text(food.description)
        //      NavigationLink(destination: GameDetailView(viewModel: .init(game: game))) {
        //        GameListItemView(viewModel: .init(game: game))
        //      }
      }
    }
  }
  
  var loadingView: some View {
    ProgressView()
  }
}

#Preview {
  GamesListView(viewModel: GamesListViewModel(container: .preview))
}
