import Foundation
import SwiftUI
import Models

public class Client: ObservableObject, Equatable {
  public static func == (lhs: Client, rhs: Client) -> Bool {
    lhs.isAuth == rhs.isAuth &&
    lhs.server == rhs.server &&
    lhs.oauthToken?.accessToken == rhs.oauthToken?.accessToken
  }
  
  public enum Version: String {
    case v1
  }
  
  public enum OauthError: Error {
    case missingApp
    case invalidRedirectURL
  }
  
  public var server: String
  public let version: Version
  private let urlSession: URLSession
  private let decoder = JSONDecoder()
  
  /// Only used as a transitionary app while in the oauth flow.
  private var oauthApp: InstanceApp?
  
  private var oauthToken: OauthToken?
  
  public var isAuth: Bool {
    oauthToken != nil
  }
  
  public init(server: String, version: Version = .v1, oauthToken: OauthToken? = nil) {
    self.server = server
    self.version = version
    self.urlSession = URLSession.shared
    self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    self.oauthToken = oauthToken
  }
  
  private func makeURL(endpoint: Endpoint) -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = server
    if type(of: endpoint) == Oauth.self {
      components.path += "/\(endpoint.path())"
    } else {
      components.path += "/api/\(version.rawValue)/\(endpoint.path())"
    }
    components.queryItems = endpoint.queryItems()
    return components.url!
  }
  
  private func makeURLRequest(url: URL, httpMethod: String) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = httpMethod
    if let oauthToken {
      request.setValue("Bearer \(oauthToken.accessToken)", forHTTPHeaderField: "Authorization")
    }
    return request
  }
    
  public func get<Entity: Decodable>(endpoint: Endpoint) async throws -> Entity {
    let url = makeURL(endpoint: endpoint)
    let request = makeURLRequest(url: url, httpMethod: "GET")
    let (data, httpResponse) = try await urlSession.data(for: request)
    logResponseOnError(httpResponse: httpResponse, data: data)
    return try decoder.decode(Entity.self, from: data)
  }
  
  public func post<Entity: Decodable>(endpoint: Endpoint) async throws -> Entity {
    let url = makeURL(endpoint: endpoint)
    let request = makeURLRequest(url: url, httpMethod: "POST")
    let (data, httpResponse) = try await urlSession.data(for: request)
    logResponseOnError(httpResponse: httpResponse, data: data)
    return try decoder.decode(Entity.self, from: data)
  }
  
  public func oauthURL() async throws -> URL {
    let app: InstanceApp = try await post(endpoint: Apps.registerApp)
    self.oauthApp = app
    return makeURL(endpoint: Oauth.authorize(clientId: app.clientId))
  }
  
  public func continueOauthFlow(url: URL) async throws -> OauthToken {
    guard let app = oauthApp else {
      throw OauthError.missingApp
    }
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let code = components.queryItems?.first(where: { $0.name == "code"})?.value else {
      throw OauthError.invalidRedirectURL
    }
    let token: OauthToken = try await post(endpoint: Oauth.token(code: code,
                                                                 clientId: app.clientId,
                                                                 clientSecret: app.clientSecret))
    self.oauthToken = token
    return token
  }
  
  private func logResponseOnError(httpResponse: URLResponse, data: Data) {
    if let httpResponse = httpResponse as? HTTPURLResponse, httpResponse.statusCode > 299 {
      print(httpResponse)
      print(String(data: data, encoding: .utf8) ?? "")
    }
  }
}
