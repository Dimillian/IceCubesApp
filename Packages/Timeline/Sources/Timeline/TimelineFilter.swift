import Foundation
import Models
import Network

public enum TimelineFilter: Hashable, Equatable {
  case pub, home
  case hashtag(tag: String, accountId: String?)
  
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
    case let .hashtag(tag, _):
      return "#\(tag)"
    }
  }
  
  func endpoint(sinceId: String?, maxId: String?) -> Endpoint {
    switch self {
    case .pub: return Timelines.pub(sinceId: sinceId, maxId: maxId)
    case .home: return Timelines.home(sinceId: sinceId, maxId: maxId)
      case let .hashtag(tag, accountId):
      if let accountId {
        return Accounts.statuses(id: accountId, sinceId: nil, tag: tag)
      } else {
        return Timelines.hashtag(tag: tag, maxId: maxId)
      }
    }
  }
}
