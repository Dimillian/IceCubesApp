import Foundation
import Models
import Network

public enum TimelineFilter: Hashable, Equatable {
  case pub, home
  case hashtag(tag: String)
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(title())
  }
  
  static func availableTimeline() -> [TimelineFilter] {
    return [.pub, .home]
  }
  
  func title() -> String {
    switch self {
    case .pub:
      return "Public"
    case .home:
      return "Home"
    case let .hashtag(tag):
      return tag
    }
  }
  
  func endpoint(sinceId: String?) -> Timelines {
    switch self {
      case .pub: return .pub(sinceId: sinceId)
      case .home: return .home(sinceId: sinceId)
      case let .hashtag(tag):
        return .hashtag(tag: tag, sinceId: sinceId)
    }
  }
}
