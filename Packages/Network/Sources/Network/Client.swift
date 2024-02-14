import Combine
import Foundation
import Models
import Observation
import os
import OSLog
import SwiftUI

@Observable public final class Client: Equatable, Identifiable, Hashable, @unchecked Sendable {
  public static func == (lhs: Client, rhs: Client) -> Bool {
    let lhsToken = lhs.critical.withLock { $0.oauthToken }
    let rhsToken = rhs.critical.withLock { $0.oauthToken }

    return (lhsToken != nil) == (rhsToken != nil) &&
      lhs.server == rhs.server &&
      lhsToken?.accessToken == rhsToken?.accessToken
  }

  public enum Version: String, Sendable {
    case v1, v2
  }

  public enum ClientError: Error {
    case unexpectedRequest
  }

  public enum OauthError: Error {
    case missingApp
    case invalidRedirectURL
  }

  public var id: String {
    critical.withLock {
      let isAuth = $0.oauthToken != nil
      return "\(isAuth)\(server)\($0.oauthToken?.createdAt ?? 0)"
    }
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public let server: String
  public let version: Version
  private let urlSession: URLSession
  private let decoder = JSONDecoder()

  private let logger = Logger(subsystem: "com.icecubesapp", category: "networking")

  // Putting all mutable state inside an `OSAllocatedUnfairLock` makes `Client`
  // provably `Sendable`. The lock is a struct, but it uses a `ManagedBuffer`
  // reference type to hold its associated state.
  private let critical: OSAllocatedUnfairLock<Critical>
  private struct Critical: Sendable {
    /// Only used as a transitionary app while in the oauth flow.
    var oauthApp: InstanceApp?
    var oauthToken: OauthToken?
    var connections: Set<String> = []
  }

  public var isAuth: Bool {
    critical.withLock { $0.oauthToken != nil }
  }

  public var connections: Set<String> {
    critical.withLock { $0.connections }
  }

  public init(server: String, version: Version = .v1, oauthToken: OauthToken? = nil) {
    self.server = server
    self.version = version
    critical = .init(initialState: Critical(oauthToken: oauthToken, connections: [server]))
    urlSession = URLSession.shared
    decoder.keyDecodingStrategy = .convertFromSnakeCase
  }

  public func addConnections(_ connections: [String]) {
    critical.withLock {
      $0.connections.formUnion(connections)
    }
  }

  public func hasConnection(with url: URL) -> Bool {
    guard let host = url.host else { return false }
    return critical.withLock {
      if let rootHost = host.split(separator: ".", maxSplits: 1).last {
        // Sometimes the connection is with the root host instead of a subdomain
        // eg. Mastodon runs on mastdon.domain.com but the connection is with domain.com
        $0.connections.contains(host) || $0.connections.contains(String(rootHost))
      } else {
        $0.connections.contains(host)
      }
    }
  }

  private func makeURL(scheme: String = "https",
                       endpoint: Endpoint,
                       forceVersion: Version? = nil,
                       forceServer: String? = nil) throws -> URL
  {
    var components = URLComponents()
    components.scheme = scheme
    components.host = forceServer ?? server
    if type(of: endpoint) == Oauth.self {
      components.path += "/\(endpoint.path())"
    } else {
      components.path += "/api/\(forceVersion?.rawValue ?? version.rawValue)/\(endpoint.path())"
    }
    components.queryItems = endpoint.queryItems()
    guard let url = components.url else {
      throw ClientError.unexpectedRequest
    }
    return url
  }

  private func makeURLRequest(url: URL, endpoint: Endpoint, httpMethod: String) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = httpMethod
    if let oauthToken = critical.withLock({ $0.oauthToken }) {
      request.setValue("Bearer \(oauthToken.accessToken)", forHTTPHeaderField: "Authorization")
    }
    if let json = endpoint.jsonValue {
      let encoder = JSONEncoder()
      encoder.keyEncodingStrategy = .convertToSnakeCase
      encoder.outputFormatting = .sortedKeys
      do {
        let jsonData = try encoder.encode(json)
        request.httpBody = jsonData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      } catch {
        logger.error("Error encoding JSON: \(error.localizedDescription)")
      }
    }
    return request
  }

  private func makeGet(endpoint: Endpoint) throws -> URLRequest {
    let url = try makeURL(endpoint: endpoint)
    return makeURLRequest(url: url, endpoint: endpoint, httpMethod: "GET")
  }

  public func get<Entity: Decodable>(endpoint: Endpoint, forceVersion: Version? = nil) async throws -> Entity {
    try await makeEntityRequest(endpoint: endpoint, method: "GET", forceVersion: forceVersion)
  }

  public func getWithLink<Entity: Decodable>(endpoint: Endpoint) async throws -> (Entity, LinkHandler?) {
    let request = try makeGet(endpoint: endpoint)
    let (data, httpResponse) = try await urlSession.data(for: request)
    var linkHandler: LinkHandler?
    if let response = httpResponse as? HTTPURLResponse,
       let link = response.allHeaderFields["Link"] as? String
    {
      linkHandler = .init(rawLink: link)
    }
    logResponseOnError(httpResponse: httpResponse, data: data)
    logger.log(level: .info, "\(request)")
    return try (decoder.decode(Entity.self, from: data), linkHandler)
  }

  public func post<Entity: Decodable>(endpoint: Endpoint, forceVersion: Version? = nil) async throws -> Entity {
    try await makeEntityRequest(endpoint: endpoint, method: "POST", forceVersion: forceVersion)
  }

  public func post(endpoint: Endpoint, forceVersion: Version? = nil) async throws -> HTTPURLResponse? {
    let url = try makeURL(endpoint: endpoint, forceVersion: forceVersion)
    let request = makeURLRequest(url: url, endpoint: endpoint, httpMethod: "POST")
    let (_, httpResponse) = try await urlSession.data(for: request)
    return httpResponse as? HTTPURLResponse
  }

  public func patch(endpoint: Endpoint) async throws -> HTTPURLResponse? {
    let url = try makeURL(endpoint: endpoint)
    let request = makeURLRequest(url: url, endpoint: endpoint, httpMethod: "PATCH")
    let (_, httpResponse) = try await urlSession.data(for: request)
    return httpResponse as? HTTPURLResponse
  }

  public func put<Entity: Decodable>(endpoint: Endpoint, forceVersion: Version? = nil) async throws -> Entity {
    try await makeEntityRequest(endpoint: endpoint, method: "PUT", forceVersion: forceVersion)
  }

  public func delete(endpoint: Endpoint, forceVersion: Version? = nil) async throws -> HTTPURLResponse? {
    let url = try makeURL(endpoint: endpoint, forceVersion: forceVersion)
    let request = makeURLRequest(url: url, endpoint: endpoint, httpMethod: "DELETE")
    let (_, httpResponse) = try await urlSession.data(for: request)
    return httpResponse as? HTTPURLResponse
  }

  private func makeEntityRequest<Entity: Decodable>(endpoint: Endpoint,
                                                    method: String,
                                                    forceVersion: Version? = nil) async throws -> Entity
  {
    let url = try makeURL(endpoint: endpoint, forceVersion: forceVersion)
    let request = makeURLRequest(url: url, endpoint: endpoint, httpMethod: method)
    let (data, httpResponse) = try await urlSession.data(for: request)
    logger.log(level: .info, "\(request)")
    logResponseOnError(httpResponse: httpResponse, data: data)
    do {
      return try decoder.decode(Entity.self, from: data)
    } catch {
      if var serverError = try? decoder.decode(ServerError.self, from: data) {
        if let httpResponse = httpResponse as? HTTPURLResponse {
          serverError.httpCode = httpResponse.statusCode
        }
        throw serverError
      }
      throw error
    }
  }

  public func oauthURL() async throws -> URL {
    let app: InstanceApp = try await post(endpoint: Apps.registerApp)
    critical.withLock { $0.oauthApp = app }
    return try makeURL(endpoint: Oauth.authorize(clientId: app.clientId))
  }

  public func continueOauthFlow(url: URL) async throws -> OauthToken {
    guard let app = critical.withLock({ $0.oauthApp }) else {
      throw OauthError.missingApp
    }
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let code = components.queryItems?.first(where: { $0.name == "code" })?.value
    else {
      throw OauthError.invalidRedirectURL
    }
    let token: OauthToken = try await post(endpoint: Oauth.token(code: code,
                                                                 clientId: app.clientId,
                                                                 clientSecret: app.clientSecret))
    critical.withLock { $0.oauthToken = token }
    return token
  }

  public func makeWebSocketTask(endpoint: Endpoint, instanceStreamingURL: URL?) throws -> URLSessionWebSocketTask {
    let url = try makeURL(scheme: "wss", endpoint: endpoint, forceServer: instanceStreamingURL?.host)
    var subprotocols: [String] = []
    if let oauthToken = critical.withLock({ $0.oauthToken }) {
      subprotocols.append(oauthToken.accessToken)
    }
    return urlSession.webSocketTask(with: url, protocols: subprotocols)
  }

  public func mediaUpload<Entity: Decodable>(endpoint: Endpoint,
                                             version: Version,
                                             method: String,
                                             mimeType: String,
                                             filename: String,
                                             data: Data) async throws -> Entity
  {
    let request = try makeFormDataRequest(endpoint: endpoint,
                                          version: version,
                                          method: method,
                                          mimeType: mimeType,
                                          filename: filename,
                                          data: data)
    let (data, httpResponse) = try await urlSession.data(for: request)
    logResponseOnError(httpResponse: httpResponse, data: data)
    do {
      return try decoder.decode(Entity.self, from: data)
    } catch {
      if let serverError = try? decoder.decode(ServerError.self, from: data) {
        throw serverError
      }
      throw error
    }
  }

  public func mediaUpload(endpoint: Endpoint,
                          version: Version,
                          method: String,
                          mimeType: String,
                          filename: String,
                          data: Data) async throws -> HTTPURLResponse?
  {
    let request = try makeFormDataRequest(endpoint: endpoint,
                                          version: version,
                                          method: method,
                                          mimeType: mimeType,
                                          filename: filename,
                                          data: data)
    let (_, httpResponse) = try await urlSession.data(for: request)
    return httpResponse as? HTTPURLResponse
  }

  private func makeFormDataRequest(endpoint: Endpoint,
                                   version: Version,
                                   method: String,
                                   mimeType: String,
                                   filename: String,
                                   data: Data) throws -> URLRequest
  {
    let url = try makeURL(endpoint: endpoint, forceVersion: version)
    var request = makeURLRequest(url: url, endpoint: endpoint, httpMethod: method)
    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    let httpBody = NSMutableData()
    httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
    httpBody.append("Content-Disposition: form-data; name=\"\(filename)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
    httpBody.append("Content-Type: \(mimeType)\r\n".data(using: .utf8)!)
    httpBody.append("\r\n".data(using: .utf8)!)
    httpBody.append(data)
    httpBody.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
    request.httpBody = httpBody as Data
    return request
  }

  private func logResponseOnError(httpResponse: URLResponse, data: Data) {
    if let httpResponse = httpResponse as? HTTPURLResponse, httpResponse.statusCode > 299 {
      let error = "HTTP Response error: \(httpResponse.statusCode), response: \(httpResponse), data: \(String(data: data, encoding: .utf8) ?? "")"
      logger.error("\(error)")
    }
  }
}
