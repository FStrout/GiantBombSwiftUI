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
      Image(systemName: "globe")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Hello, world!")
    }
    .padding()
  }
}

#Preview {
  GamesListView(viewModel: GamesListViewModel(container: .preview))
}
