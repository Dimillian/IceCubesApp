import Foundation
import Models
import Network
import SwiftUI

public enum RemoteTimelineFilter: String, CaseIterable, Hashable, Equatable, Sendable {
  case local, federated, trending

  public func localizedTitle() -> LocalizedStringKey {
    switch self {
    case .federated:
      "timeline.federated"
    case .local:
      "timeline.local"
    case .trending:
      "timeline.trending"
    }
  }

  public func iconName() -> String {
    switch self {
    case .federated:
      "globe.americas"
    case .local:
      "person.2"
    case .trending:
      "chart.line.uptrend.xyaxis"
    }
  }
}

public enum TimelineFilter: Hashable, Equatable, Identifiable, Sendable {
  case home, local, federated, trending
  case hashtag(tag: String, accountId: String?)
  case tagGroup(title: String, tags: [String], symbolName: String?)
  case list(list: Models.List)
  case remoteLocal(server: String, filter: RemoteTimelineFilter)
  case latest
  case resume

  public var id: String {
    switch self {
    case let .remoteLocal(server, filter):
      return server + filter.rawValue
    case let .list(list):
      return list.id
    case let .tagGroup(title, tags, _):
      return title + tags.joined()
    default:
      return title
    }
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public static func availableTimeline(client: Client) -> [TimelineFilter] {
    if !client.isAuth {
      return [.local, .federated, .trending]
    }
    return [.home, .local, .federated, .trending]
  }

  public var supportNewestPagination: Bool {
    switch self {
    case .trending:
      false
    case let .remoteLocal(_, filter):
      filter != .trending
    default:
      true
    }
  }

  public var title: String {
    switch self {
    case .latest:
      "Latest"
    case .resume:
      "Resume"
    case .federated:
      "Federated"
    case .local:
      "Local"
    case .trending:
      "Trending"
    case .home:
      "Home"
    case let .hashtag(tag, _):
      "#\(tag)"
    case let .tagGroup(title, _, _):
      title
    case let .list(list):
      list.title
    case let .remoteLocal(server, _):
      server
    }
  }

  public func localizedTitle() -> LocalizedStringKey {
    switch self {
    case .latest:
      "timeline.latest"
    case .resume:
      "timeline.resume"
    case .federated:
      "timeline.federated"
    case .local:
      "timeline.local"
    case .trending:
      "timeline.trending"
    case .home:
      "timeline.home"
    case let .hashtag(tag, _):
      "#\(tag)"
    case let .tagGroup(title, _, _):
      LocalizedStringKey(title) // ?? not sure since this can't be localized.
    case let .list(list):
      LocalizedStringKey(list.title)
    case let .remoteLocal(server, _):
      LocalizedStringKey(server)
    }
  }

  public func iconName() -> String {
    switch self {
    case .latest:
      "arrow.counterclockwise"
    case .resume:
      "clock.arrow.2.circlepath"
    case .federated:
      "globe.americas"
    case .local:
      "person.2"
    case .trending:
      "chart.line.uptrend.xyaxis"
    case .home:
      "house"
    case .list:
      "list.bullet"
    case .remoteLocal:
      "dot.radiowaves.right"
    case let .tagGroup(_, _, symbolName):
      symbolName ?? "tag"
    case .hashtag:
      "number"
    }
  }

  public func endpoint(sinceId: String?, maxId: String?, minId: String?, offset: Int?) -> Endpoint {
    switch self {
    case .federated: return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: false)
    case .local: return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: true)
    case let .remoteLocal(_, filter):
      switch filter {
      case .local:
        return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: true)
      case .federated:
        return Timelines.pub(sinceId: sinceId, maxId: maxId, minId: minId, local: false)
      case .trending:
        return Trends.statuses(offset: offset)
      }
    case .latest: return Timelines.home(sinceId: nil, maxId: nil, minId: nil)
    case .resume: return Timelines.home(sinceId: nil, maxId: nil, minId: nil)
    case .home: return Timelines.home(sinceId: sinceId, maxId: maxId, minId: minId)
    case .trending: return Trends.statuses(offset: offset)
    case let .list(list): return Timelines.list(listId: list.id, sinceId: sinceId, maxId: maxId, minId: minId)
    case let .hashtag(tag, accountId):
      if let accountId {
        return Accounts.statuses(id: accountId,
                                 sinceId: nil,
                                 tag: tag,
                                 onlyMedia: false,
                                 excludeReplies: false,
                                 excludeReblogs: false,
                                 pinned: nil)
      } else {
        return Timelines.hashtag(tag: tag, additional: nil, maxId: maxId, minId: minId)
      }
    case let .tagGroup(_, tags, _):
      var tags = tags
      if !tags.isEmpty {
        let tag = tags.removeFirst()
        return Timelines.hashtag(tag: tag, additional: tags, maxId: maxId, minId: minId)
      } else {
        return Timelines.hashtag(tag: "", additional: tags, maxId: maxId, minId: minId)
      }
    }
  }
}

extension TimelineFilter: Codable {
  enum CodingKeys: String, CodingKey {
    case home
    case local
    case federated
    case trending
    case hashtag
    case tagGroup
    case list
    case remoteLocal
    case latest
    case resume
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let key = container.allKeys.first
    switch key {
    case .home:
      self = .home
    case .local:
      self = .local
    case .federated:
      self = .federated
    case .trending:
      self = .trending
    case .hashtag:
      var nestedContainer = try container.nestedUnkeyedContainer(forKey: .hashtag)
      let tag = try nestedContainer.decode(String.self)
      let accountId = try nestedContainer.decode(String?.self)
      self = .hashtag(
        tag: tag,
        accountId: accountId
      )
    case .tagGroup:
      var nestedContainer = try container.nestedUnkeyedContainer(forKey: .tagGroup)
      let title = try nestedContainer.decode(String.self)
      let tags = try nestedContainer.decode([String].self)
      let symbolName = try? nestedContainer.decode(String.self)
      self = .tagGroup(
        title: title,
        tags: tags,
        symbolName: symbolName
      )
    case .list:
      let list = try container.decode(
        Models.List.self,
        forKey: .list
      )
      self = .list(list: list)
    case .remoteLocal:
      var nestedContainer = try container.nestedUnkeyedContainer(forKey: .remoteLocal)
      let server = try nestedContainer.decode(String.self)
      let filter = try nestedContainer.decode(RemoteTimelineFilter.self)
      self = .remoteLocal(
        server: server,
        filter: filter
      )
    case .latest:
      self = .latest
    default:
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Unabled to decode enum."
        )
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .home:
      try container.encode(CodingKeys.home.rawValue, forKey: .home)
    case .local:
      try container.encode(CodingKeys.local.rawValue, forKey: .local)
    case .federated:
      try container.encode(CodingKeys.federated.rawValue, forKey: .federated)
    case .trending:
      try container.encode(CodingKeys.trending.rawValue, forKey: .trending)
    case let .hashtag(tag, accountId):
      var nestedContainer = container.nestedUnkeyedContainer(forKey: .hashtag)
      try nestedContainer.encode(tag)
      try nestedContainer.encode(accountId)
    case let .tagGroup(title, tags, symbolName):
      var nestedContainer = container.nestedUnkeyedContainer(forKey: .tagGroup)
      try nestedContainer.encode(title)
      try nestedContainer.encode(tags)
      try? nestedContainer.encode(symbolName)
    case let .list(list):
      try container.encode(list, forKey: .list)
    case let .remoteLocal(server, filter):
      var nestedContainer = container.nestedUnkeyedContainer(forKey: .remoteLocal)
      try nestedContainer.encode(server)
      try nestedContainer.encode(filter)
    case .latest:
      try container.encode(CodingKeys.latest.rawValue, forKey: .latest)
    case .resume:
      try container.encode(CodingKeys.resume.rawValue, forKey: .latest)
    }
  }
}

extension TimelineFilter: RawRepresentable {
  public init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
          let result = try? JSONDecoder().decode(TimelineFilter.self, from: data)
    else {
      return nil
    }
    self = result
  }

  public var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
          let result = String(data: data, encoding: .utf8)
    else {
      return "[]"
    }
    return result
  }
}

extension RemoteTimelineFilter: Codable {
  enum CodingKeys: String, CodingKey {
    case local
    case federated
    case trending
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let key = container.allKeys.first
    switch key {
    case .local:
      self = .local
    case .federated:
      self = .federated
    case .trending:
      self = .trending
    default:
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: container.codingPath,
          debugDescription: "Unabled to decode enum."
        )
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .local:
      try container.encode(CodingKeys.local.rawValue, forKey: .local)
    case .federated:
      try container.encode(CodingKeys.federated.rawValue, forKey: .federated)
    case .trending:
      try container.encode(CodingKeys.trending.rawValue, forKey: .trending)
    }
  }
}

extension RemoteTimelineFilter: RawRepresentable {
  public init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
          let result = try? JSONDecoder().decode(RemoteTimelineFilter.self, from: data)
    else {
      return nil
    }
    self = result
  }

  public var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
          let result = String(data: data, encoding: .utf8)
    else {
      return "[]"
    }
    return result
  }
}
