import Foundation
import Models

public struct SubClubClient: Sendable {
  public enum Endpoint {
    case user(username: String)

    var path: String {
      switch self {
      case .user(let username):
        return "users/\(username)"
      }
    }
  }

  public init() {}

  private var url: String {
    "https://\(AppInfo.premiumInstance)/"
  }

  public func getUser(username: String) async -> SubClubUser? {
    guard let url = URL(string: url.appending(Endpoint.user(username: username).path)) else {
      return nil
    }
    let request = URLRequest(url: url)
    do {
      let (result, _) = try await URLSession.shared.data(for: request)
      let decoder = JSONDecoder()
      let user = try decoder.decode(SubClubUser.self, from: result)
      return user
    } catch {
      return nil
    }
  }
}
