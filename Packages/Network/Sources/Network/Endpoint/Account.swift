import Foundation

public enum Account: Endpoint {
  case accounts(id: String)
  
  public func path() -> String {
    switch self {
    case .accounts(let id):
      return "accounts/\(id)"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    nil
  }
}
