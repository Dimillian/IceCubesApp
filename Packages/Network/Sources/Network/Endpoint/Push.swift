import Foundation

public enum Push: Endpoint {
  case subscription
  case createSub(
    endpoint: String,
    p256dh: Data,
    auth: Data,
    mentions: Bool,
    status: Bool,
    reblog: Bool,
    follow: Bool,
    favorite: Bool,
    poll: Bool)

  public func path() -> String {
    switch self {
    case .subscription, .createSub:
      "push/subscription"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .createSub(endpoint, p256dh, auth, mentions, status, reblog, follow, favorite, poll):
      var params: [URLQueryItem] = []
      params.append(.init(name: "subscription[endpoint]", value: endpoint))
      params.append(
        .init(name: "subscription[keys][p256dh]", value: p256dh.base64UrlEncodedString()))
      params.append(.init(name: "subscription[keys][auth]", value: auth.base64UrlEncodedString()))
      params.append(.init(name: "data[alerts][mention]", value: mentions ? "true" : "false"))
      params.append(.init(name: "data[alerts][status]", value: status ? "true" : "false"))
      params.append(.init(name: "data[alerts][follow]", value: follow ? "true" : "false"))
      params.append(.init(name: "data[alerts][reblog]", value: reblog ? "true" : "false"))
      params.append(.init(name: "data[alerts][favourite]", value: favorite ? "true" : "false"))
      params.append(.init(name: "data[alerts][poll]", value: poll ? "true" : "false"))
      params.append(.init(name: "policy", value: "all"))
      return params
    default:
      return nil
    }
  }
}
