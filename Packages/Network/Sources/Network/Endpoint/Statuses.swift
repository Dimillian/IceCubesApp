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
  case translate(id: String, lang: String?)
  case report(accountId: String, statusId: String, comment: String)

  public func path() -> String {
    switch self {
    case .postStatus:
      "statuses"
    case let .status(id):
      "statuses/\(id)"
    case let .editStatus(id, _):
      "statuses/\(id)"
    case let .context(id):
      "statuses/\(id)/context"
    case let .favorite(id):
      "statuses/\(id)/favourite"
    case let .unfavorite(id):
      "statuses/\(id)/unfavourite"
    case let .reblog(id):
      "statuses/\(id)/reblog"
    case let .unreblog(id):
      "statuses/\(id)/unreblog"
    case let .rebloggedBy(id, _):
      "statuses/\(id)/reblogged_by"
    case let .favoritedBy(id, _):
      "statuses/\(id)/favourited_by"
    case let .pin(id):
      "statuses/\(id)/pin"
    case let .unpin(id):
      "statuses/\(id)/unpin"
    case let .bookmark(id):
      "statuses/\(id)/bookmark"
    case let .unbookmark(id):
      "statuses/\(id)/unbookmark"
    case let .history(id):
      "statuses/\(id)/history"
    case let .translate(id, _):
      "statuses/\(id)/translate"
    case .report:
      "reports"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .rebloggedBy(_, maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    case let .favoritedBy(_, maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    case let .translate(_, lang):
      if let lang {
        return [.init(name: "lang", value: lang)]
      }
      return nil
    case let .report(accountId, statusId, comment):
      return [.init(name: "account_id", value: accountId),
              .init(name: "status_ids[]", value: statusId),
              .init(name: "comment", value: comment)]
    default:
      return nil
    }
  }

  public var jsonValue: Encodable? {
    switch self {
    case let .postStatus(json):
      json
    case let .editStatus(_, json):
      json
    default:
      nil
    }
  }
}

public struct StatusData: Encodable, Sendable {
  public let status: String
  public let visibility: Visibility
  public let inReplyToId: String?
  public let spoilerText: String?
  public let mediaIds: [String]?
  public let poll: PollData?
  public let language: String?
  public let mediaAttributes: [MediaAttribute]?

  public struct PollData: Encodable, Sendable {
    public let options: [String]
    public let multiple: Bool
    public let expires_in: Int

    public init(options: [String], multiple: Bool, expires_in: Int) {
      self.options = options
      self.multiple = multiple
      self.expires_in = expires_in
    }
  }

  public struct MediaAttribute: Encodable, Sendable {
    public let id: String
    public let description: String?
    public let thumbnail: String?
    public let focus: String?

    public init(id: String, description: String?, thumbnail: String?, focus: String?) {
      self.id = id
      self.description = description
      self.thumbnail = thumbnail
      self.focus = focus
    }
  }

  public init(status: String,
              visibility: Visibility,
              inReplyToId: String? = nil,
              spoilerText: String? = nil,
              mediaIds: [String]? = nil,
              poll: PollData? = nil,
              language: String? = nil,
              mediaAttributes: [MediaAttribute]? = nil)
  {
    self.status = status
    self.visibility = visibility
    self.inReplyToId = inReplyToId
    self.spoilerText = spoilerText
    self.mediaIds = mediaIds
    self.poll = poll
    self.language = language
    self.mediaAttributes = mediaAttributes
  }
}
