import Foundation
import Models

public enum Accounts: Endpoint {
  case accounts(id: String)
  case lookup(name: String)
  case favorites(sinceId: String?)
  case bookmarks(sinceId: String?)
  case followedTags
  case featuredTags(id: String)
  case verifyCredentials
  case updateCredentialsMedia
  case updateCredentials(json: UpdateCredentialsData)
  case statuses(id: String,
                sinceId: String?,
                tag: String?,
                onlyMedia: Bool,
                excludeReplies: Bool,
                excludeReblogs: Bool,
                pinned: Bool?)
  case relationships(ids: [String])
  case follow(id: String, notify: Bool, reblogs: Bool)
  case unfollow(id: String)
  case familiarFollowers(withAccount: String)
  case suggestions
  case followers(id: String, maxId: String?)
  case following(id: String, maxId: String?)
  case lists(id: String)
  case preferences
  case block(id: String)
  case unblock(id: String)
  case mute(id: String, json: MuteData)
  case unmute(id: String)
  case relationshipNote(id: String, json: RelationshipNoteData)
  case blockList
  case muteList

  public func path() -> String {
    switch self {
    case let .accounts(id):
      "accounts/\(id)"
    case .lookup:
      "accounts/lookup"
    case .favorites:
      "favourites"
    case .bookmarks:
      "bookmarks"
    case .followedTags:
      "followed_tags"
    case let .featuredTags(id):
      "accounts/\(id)/featured_tags"
    case .verifyCredentials:
      "accounts/verify_credentials"
    case .updateCredentials, .updateCredentialsMedia:
      "accounts/update_credentials"
    case let .statuses(id, _, _, _, _, _, _):
      "accounts/\(id)/statuses"
    case .relationships:
      "accounts/relationships"
    case let .follow(id, _, _):
      "accounts/\(id)/follow"
    case let .unfollow(id):
      "accounts/\(id)/unfollow"
    case .familiarFollowers:
      "accounts/familiar_followers"
    case .suggestions:
      "suggestions"
    case let .following(id, _):
      "accounts/\(id)/following"
    case let .followers(id, _):
      "accounts/\(id)/followers"
    case let .lists(id):
      "accounts/\(id)/lists"
    case .preferences:
      "preferences"
    case let .block(id):
      "accounts/\(id)/block"
    case let .unblock(id):
      "accounts/\(id)/unblock"
    case let .mute(id, _):
      "accounts/\(id)/mute"
    case let .unmute(id):
      "accounts/\(id)/unmute"
    case let .relationshipNote(id, _):
      "accounts/\(id)/note"
    case .blockList:
      "blocks"
    case .muteList:
      "mutes"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .lookup(name):
      return [
        .init(name: "acct", value: name),
      ]
    case let .statuses(_, sinceId, tag, onlyMedia, excludeReplies, excludeReblogs, pinned):
      var params: [URLQueryItem] = []
      if let tag {
        params.append(.init(name: "tagged", value: tag))
      }
      if let sinceId {
        params.append(.init(name: "max_id", value: sinceId))
      }

      params.append(.init(name: "only_media", value: onlyMedia ? "true" : "false"))
      params.append(.init(name: "exclude_replies", value: excludeReplies ? "true" : "false"))
      params.append(.init(name: "exclude_reblogs", value: excludeReblogs ? "true" : "false"))

      if let pinned {
        params.append(.init(name: "pinned", value: pinned ? "true" : "false"))
      }
      return params
    case let .relationships(ids):
      return ids.map {
        URLQueryItem(name: "id[]", value: $0)
      }
    case let .follow(_, notify, reblogs):
      return [
        .init(name: "notify", value: notify ? "true" : "false"),
        .init(name: "reblogs", value: reblogs ? "true" : "false"),
      ]
    case let .familiarFollowers(withAccount):
      return [.init(name: "id[]", value: withAccount)]
    case let .followers(_, maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    case let .following(_, maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    case let .favorites(sinceId):
      guard let sinceId else { return nil }
      return [.init(name: "max_id", value: sinceId)]
    case let .bookmarks(sinceId):
      guard let sinceId else { return nil }
      return [.init(name: "max_id", value: sinceId)]
    default:
      return nil
    }
  }

  public var jsonValue: Encodable? {
    switch self {
    case let .mute(_, json):
      json
    case let .relationshipNote(_, json):
      json
    case let .updateCredentials(json):
      json
    default:
      nil
    }
  }
}

public struct MuteData: Encodable, Sendable {
  public let duration: Int

  public init(duration: Int) {
    self.duration = duration
  }
}

public struct RelationshipNoteData: Encodable, Sendable {
  public let comment: String

  public init(note comment: String) {
    self.comment = comment
  }
}

public struct UpdateCredentialsData: Encodable, Sendable {
  public struct SourceData: Encodable, Sendable {
    public let privacy: Visibility
    public let sensitive: Bool

    public init(privacy: Visibility, sensitive: Bool) {
      self.privacy = privacy
      self.sensitive = sensitive
    }
  }

  public struct FieldData: Encodable, Sendable {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
      self.name = name
      self.value = value
    }
  }

  public let displayName: String
  public let note: String
  public let source: SourceData
  public let bot: Bool
  public let locked: Bool
  public let discoverable: Bool
  public let fieldsAttributes: [String: FieldData]

  public init(displayName: String,
              note: String,
              source: UpdateCredentialsData.SourceData,
              bot: Bool,
              locked: Bool,
              discoverable: Bool,
              fieldsAttributes: [FieldData])
  {
    self.displayName = displayName
    self.note = note
    self.source = source
    self.bot = bot
    self.locked = locked
    self.discoverable = discoverable

    var fieldAttributes: [String: FieldData] = [:]
    for (index, field) in fieldsAttributes.enumerated() {
      fieldAttributes[String(index)] = field
    }
    self.fieldsAttributes = fieldAttributes
  }
}
