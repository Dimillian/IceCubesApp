import Foundation
import Models
import Network

public enum TimelineFilter: Hashable, Equatable {
  case pub, local, home, trending
  case hashtag(tag: String, accountId: String?)
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(title())
  }
  
  public static func availableTimeline(client: Client) -> [TimelineFilter] {
    if !client.isAuth {
      return [.pub, .local, .trending]
    }
    return [.pub, .local, .trending, .home]
  }
  
  public func title() -> String {
    switch self {
    case .pub:
      return "Federated"
    case .local:
      return "Local"
    case .trending:
      return "Trending"
    case .home:
      return "Home"
    case let .hashtag(tag, _):
      return "#\(tag)"
    }
  }
  
  public func iconName() -> String? {
    switch self {
    case .pub:
      return "globe.americas"
    case .local:
      return "person.3"
    case .trending:
      return "chart.line.uptrend.xyaxis"
    case .home:
      return "house"
    default:
      return nil
    }
  }
  
  public func endpoint(sinceId: String?, maxId: String?, minId: String?, offset: Int?) -> Endpoint {
    switch self {
    case .pub: return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: false)
    case .local: return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: true)
    case .home: return Timelines.home(sinceId: sinceId, maxId: maxId, minId: minId)
    case .trending: return Trends.statuses(offset: offset)
      case let .hashtag(tag, accountId):
      if let accountId {
        return Accounts.statuses(id: accountId, sinceId: nil, tag: tag, onlyMedia: nil, excludeReplies: nil)
      } else {
        return Timelines.hashtag(tag: tag, maxId: maxId)
      }
    }
  }
}
