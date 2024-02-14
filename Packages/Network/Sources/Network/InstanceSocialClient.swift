import Foundation
import Models

public struct InstanceSocialClient: Sendable {
  private let authorization = "Bearer 8a4xx3D7Hzu1aFnf18qlkH8oU0oZ5ulabXxoS2FtQtwOy8G0DGQhr5PjTIjBnYAmFrSBuE2CcASjFocxJBonY8XGbLySB7MXd9ssrwlRHUXTQh3Z578lE1OfUtafvhML"
  private let listEndpoint = "https://instances.social/api/1.0/instances/list?count=1000&include_closed=false&include_dead=false&min_active_users=500"
  private let searchEndpoint = "https://instances.social/api/1.0/instances/search"

  struct Response: Decodable {
    let instances: [InstanceSocial]
  }

  public init() {}

  public func fetchInstances(keyword: String) async -> [InstanceSocial] {
    let keyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)

    let endpoint = keyword.isEmpty ? listEndpoint : searchEndpoint + "?q=\(keyword)"

    guard let url = URL(string: endpoint) else { return [] }

    var request = URLRequest(url: url)
    request.setValue(authorization, forHTTPHeaderField: "Authorization")

    guard let (data, _) = try? await URLSession.shared.data(for: request) else { return [] }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    guard let response = try? decoder.decode(Response.self, from: data) else { return [] }

    let result = response.instances.sorted(by: keyword)
    return result
  }
}

private extension Array where Self.Element == InstanceSocial {
  func sorted(by keyword: String) -> Self {
    let keyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    var newArray = self

    newArray.sort { (lhs: InstanceSocial, rhs: InstanceSocial) in
      guard
        let lhsNumber = Int(lhs.users),
        let rhsNumber = Int(rhs.users)
      else { return false }

      return lhsNumber > rhsNumber
    }

    newArray.sort { (lhs: InstanceSocial, rhs: InstanceSocial) in
      guard
        let lhsNumber = Int(lhs.statuses),
        let rhsNumber = Int(rhs.statuses)
      else { return false }

      return lhsNumber > rhsNumber
    }

    if !keyword.isEmpty {
      newArray.sort { (lhs: InstanceSocial, rhs: InstanceSocial) in
        if
          lhs.name.contains(keyword),
          !rhs.name.contains(keyword)
        { return true }

        return false
      }
    }

    return newArray
  }
}
