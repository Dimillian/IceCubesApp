import Foundation
import Models

public enum Statuses: Endpoint {
  case postStatus(json: StatusData)
  case editStatus(id: String, json: StatusData)
  case status(id: String)
  case context(id: String)
  case favorite(id: String)
  case unfavorite(id: String)
  case reblog(id: String)
  case unreblog(id: String)
  case rebloggedBy(id: String, maxId: String?)
  case favoritedBy(id: String, maxId: String?)
  case pin(id: String)
  case unpin(id: String)
  case bookmark(id: String)
  case unbookmark(id: String)
  case history(id: String)

  public func path() -> String {
    switch self {
    case .postStatus:
      return "statuses"
    case let .status(id):
      return "statuses/\(id)"
    case let .editStatus(id, _):
      return "statuses/\(id)"
    case let .context(id):
      return "statuses/\(id)/context"
    case let .favorite(id):
      return "statuses/\(id)/favourite"
    case let .unfavorite(id):
      return "statuses/\(id)/unfavourite"
    case let .reblog(id):
      return "statuses/\(id)/reblog"
    case let .unreblog(id):
      return "statuses/\(id)/unreblog"
    case let .rebloggedBy(id, _):
      return "statuses/\(id)/reblogged_by"
    case let .favoritedBy(id, _):
      return "statuses/\(id)/favourited_by"
    case let .pin(id):
      return "statuses/\(id)/pin"
    case let .unpin(id):
      return "statuses/\(id)/unpin"
    case let .bookmark(id):
      return "statuses/\(id)/bookmark"
    case let .unbookmark(id):
      return "statuses/\(id)/unbookmark"
    case let .history(id):
      return "statuses/\(id)/history"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .rebloggedBy(_, maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    case let .favoritedBy(_, maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    default:
      return nil
    }
  }

  public var jsonValue: Encodable? {
    switch self {
    case let .postStatus(json):
      return json
    case let .editStatus(_, json):
      return json
    default:
      return nil
    }
  }
}

public struct StatusData: Encodable {
  public let status: String
  public let visibility: Visibility
  public let inReplyToId: String?
  public let spoilerText: String?
  public let mediaIds: [String]?
  public let poll: PollData?
  public let language: String?

  public struct PollData: Encodable {
    public let options: [String]
    public let multiple: Bool
    public let expires_in: Int

    public init(options: [String], multiple: Bool, expires_in: Int) {
      self.options = options
      self.multiple = multiple
      self.expires_in = expires_in
    }
  }

  public init(status: String,
              visibility: Visibility,
              inReplyToId: String? = nil,
              spoilerText: String? = nil,
              mediaIds: [String]? = nil,
              poll: PollData? = nil,
              language: String? = nil)
  {
    self.status = status
    self.visibility = visibility
    self.inReplyToId = inReplyToId
    self.spoilerText = spoilerText
    self.mediaIds = mediaIds
    self.poll = poll
    self.language = language
  }
}
