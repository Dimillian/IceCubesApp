import Foundation

public enum Timeline: Endpoint {
  case pub
  
  public func path() -> String {
    switch self {
    case .pub:
      return "timelines/public"
    }
  }
}
