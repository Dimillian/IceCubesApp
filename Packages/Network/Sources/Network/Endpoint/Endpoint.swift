import Foundation

public protocol Endpoint {
  func path() -> String
  func queryItems() -> [URLQueryItem]?
}
