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
    case .development:  return "https://api.gamebrain.co/v1"
    case .staging:      return "https://api.gamebrain.co/v1"
    case .production:   return "https://api.gamebrain.co/v1"
    }
  }
  
  static var usdaApiBaseURL: String {
    switch current {
    case .development:  return "https://api.nal.usda.gov/fdc/v1"
    case .staging:      return "https://api.nal.usda.gov/fdc/v1"
    case .production:   return "https://api.nal.usda.gov/fdc/v1"
    }
  }
  
  /// API key / token — read from Info.plist in production.
  static let apiKey: String = "79dc94acb32449abb82c4aef80b18968"
  static let usdaApiKey: String = "ycCVTkMlMpQj44wUdzVqWFGDelJ0QJQLLMxO9wWq"
}
