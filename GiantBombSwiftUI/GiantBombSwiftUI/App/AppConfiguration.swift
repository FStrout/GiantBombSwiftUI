//
//  AppConfiguration.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/26/26.
//

import Foundation

enum AppConfiguration {
  
  // MARK: - Environment Detection
  
  enum Environment {
    case development
    case staging
    case production
  }
  
  /// Change this to switch environments, or drive it from a build flag.
  static let current: Environment = {
#if DEBUG
    return .development
#else
    return .production
#endif
  }()
  
  // MARK: - API
  
  static var apiBaseURL: String {
    switch current {
    case .development:  return "https://www.giantbomb.com/api"
    case .staging:      return "https://www.giantbomb.com/api"
    case .production:   return "https://www.giantbomb.com/api"
    }
  }
  
  /// API key / token — read from Info.plist in production.
  static let apiKey: String = "d1c95cbbe827f44c2d4a6eb17556b9427415fff7"
}
