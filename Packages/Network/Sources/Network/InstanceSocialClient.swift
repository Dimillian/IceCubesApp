import Foundation
import Models

public struct InstanceSocialClient {
  private let authorization = "Bearer 8a4xx3D7Hzu1aFnf18qlkH8oU0oZ5ulabXxoS2FtQtwOy8G0DGQhr5PjTIjBnYAmFrSBuE2CcASjFocxJBonY8XGbLySB7MXd9ssrwlRHUXTQh3Z578lE1OfUtafvhML"
  private let endpoint = URL(string: "https://instances.social/api/1.0/instances/list?count=1000&include_closed=false&include_dead=false&min_active_users=500")!

  struct Response: Decodable {
    let instances: [InstanceSocial]
  }

  public init() {}

  public func fetchInstances() async -> [InstanceSocial] {
    do {
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      var request: URLRequest = .init(url: endpoint)
      request.setValue(authorization, forHTTPHeaderField: "Authorization")
      let (data, _) = try await URLSession.shared.data(for: request)
      let response = try decoder.decode(Response.self, from: data)
      return response.instances
    } catch {
      return []
    }
  }
}
