//
//  APIEndpoint.swift
//  GiantBombSwiftUI
//
//  Created by Fred Strout on 3/26/26.
//

import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String {
  case get    = "GET"
  case post   = "POST"
  case put    = "PUT"
  case patch  = "PATCH"
  case delete = "DELETE"
}

// MARK: - APIEndpoint Protocol

/// Describes a single REST endpoint. Create an enum in each feature that
/// conforms to this protocol to keep endpoint definitions close to the
/// code that uses them.
protocol APIEndpoint {
  /// Base URL for all requests (e.g. "https://api.example.com")
  var baseURL: String { get }
  
  /// Path component appended to baseURL (e.g. "/users/profile")
  var path: String { get }
  
  /// HTTP method for this endpoint
  var method: HTTPMethod { get }
  
  /// HTTP headers to include. The APIService will merge these with
  /// any global headers (e.g. Authorization).
  var headers: [String: String]? { get }
  
  /// Query parameters appended to the URL
  var queryItems: [URLQueryItem]? { get }
  
  /// Request body, if any. Will be JSON-encoded automatically.
  var body: Encodable? { get }
}

// MARK: - Default Implementations

extension APIEndpoint {
  var headers: [String: String]? { nil }
  var queryItems: [URLQueryItem]? { nil }
  var body: Encodable? { nil }
  
  /// Builds the complete URLRequest from the endpoint's properties.
  func asURLRequest() throws -> URLRequest {
    guard var components = URLComponents(string: baseURL + path) else {
      throw APIError.invalidURL
    }
    components.queryItems = queryItems
    
    guard let url = components.url else {
      throw APIError.invalidURL
    }
    
    print("📡 API Request URL: \(url.absoluteString)")
    
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    
    headers?.forEach { key, value in
      request.setValue(value, forHTTPHeaderField: key)
    }
    
    if let body {
      do {
        request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
      } catch {
        throw APIError.encodingFailed(error)
      }
    }
    
    return request
  }
}

// MARK: - Type-erased Encodable helper

/// Allows encoding `any Encodable` stored as an existential.
private struct AnyEncodable: Encodable {
  private let _encode: (Encoder) throws -> Void
  
  init(_ value: Encodable) {
    self._encode = value.encode
  }
  
  func encode(to encoder: Encoder) throws {
    try _encode(encoder)
  }
}

enum GameEndpoint: APIEndpoint {
  case getGame(searchString: String)
  
  var baseURL: String { AppConfiguration.apiBaseURL }
  
  var headers: [String : String]? {
    ["x-api-key": "\(AppConfiguration.apiKey)"]
  }
  
  var path: String {
    switch self {
    case .getGame:
      return "/games"
    }
  }
  
  var queryItems: [URLQueryItem]? {
    switch self {
    case .getGame(let searchString):
      return [
        URLQueryItem(name: "query", value: searchString)
      ]
    }
  }
  
  var method: HTTPMethod { .get }
}
