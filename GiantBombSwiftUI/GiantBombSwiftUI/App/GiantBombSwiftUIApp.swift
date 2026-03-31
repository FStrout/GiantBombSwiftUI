//
//  GiantBombSwiftUIApp.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/26/26.
//

import SwiftUI

@main
struct GiantBombSwiftUIApp: App {
  
  // The container is created once here and passed down via environment.
  @StateObject private var container = DIContainer.shared
  
  var body: some Scene {
    WindowGroup {
      // SleepAnalysisView(viewModel: HealthKitViewModel(container: container))
      GamesListView(viewModel: GamesListViewModel(container: container))
        .environmentObject(container)
    }
  }
}
