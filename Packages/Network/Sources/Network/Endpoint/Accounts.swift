import Foundation

public enum Accounts: Endpoint {
  case accounts(id: String)
  case verifyCredentials
  case statuses(id: String, sinceId: String?)
  
  public func path() -> String {
    switch self {
    case .accounts(let id):
      return "accounts/\(id)"
    case .verifyCredentials:
      return "accounts/verify_credentials"
    case .statuses(let id, _):
      return "accounts/\(id)/statuses"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .statuses(_, let sinceId):
      guard let sinceId else { return nil }
      return [.init(name: "max_id", value: sinceId)]
    default:
      return nil
    }
  }
}
