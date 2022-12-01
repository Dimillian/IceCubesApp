import Foundation

public enum Accounts: Endpoint {
  case accounts(id: String)
  case verifyCredentials
  
  public func path() -> String {
    switch self {
    case .accounts(let id):
      return "accounts/\(id)"
    case .verifyCredentials:
      return "accounts/verify_credentials"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    nil
  }
}
