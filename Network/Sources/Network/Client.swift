import Foundation

public struct Client {
  public enum Version: String {
    case v1
  }
  
  public let server: String
  public let version: Version
  private let urlSession: URLSession
  private let decoder = JSONDecoder()
  
  public init(server: String, version: Version = .v1) {
    self.server = server
    self.version = version
    self.urlSession = URLSession.shared
    self.decoder.keyDecodingStrategy = .convertFromSnakeCase
  }
  
  private func makeURL(endpoint: Endpoint) -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = server
    components.path += "/api/\(version.rawValue)/\(endpoint.path())"
    return components.url!
  }
    
  public func fetch<Entity: Codable>(endpoint: Endpoint) async throws -> Entity {
    let (data, _) = try await urlSession.data(from: makeURL(endpoint: endpoint))
    return try decoder.decode(Entity.self, from: data)
  }
  
  public func fetchArray<Entity: Codable>(endpoint: Endpoint) async throws -> [Entity] {
    let (data, _) = try await urlSession.data(from: makeURL(endpoint: endpoint))
    return try decoder.decode([Entity].self, from: data)
  }
}
