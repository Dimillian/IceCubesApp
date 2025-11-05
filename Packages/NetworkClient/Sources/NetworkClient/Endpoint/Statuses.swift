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
  case quotesBy(id: String, maxId: String?)
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
    case .status(let id):
      "statuses/\(id)"
    case .editStatus(let id, _):
      "statuses/\(id)"
    case .context(let id):
      "statuses/\(id)/context"
    case .favorite(let id):
      "statuses/\(id)/favourite"
    case .unfavorite(let id):
      "statuses/\(id)/unfavourite"
    case .reblog(let id):
      "statuses/\(id)/reblog"
    case .unreblog(let id):
      "statuses/\(id)/unreblog"
    case .rebloggedBy(let id, _):
      "statuses/\(id)/reblogged_by"
    case .favoritedBy(let id, _):
      "statuses/\(id)/favourited_by"
    case .quotesBy(let id, _):
      "statuses/\(id)/quotes"
    case .pin(let id):
      "statuses/\(id)/pin"
    case .unpin(let id):
      "statuses/\(id)/unpin"
    case .bookmark(let id):
      "statuses/\(id)/bookmark"
    case .unbookmark(let id):
      "statuses/\(id)/unbookmark"
    case .history(let id):
      "statuses/\(id)/history"
    case .translate(let id, _):
      "statuses/\(id)/translate"
    case .report:
      "reports"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case .rebloggedBy(_, let maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    case .favoritedBy(_, let maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    case .quotesBy(_, let maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    case .translate(_, let lang):
      if let lang {
        return [.init(name: "lang", value: lang)]
      }
      return nil
    case .report(let accountId, let statusId, let comment):
      return [
        .init(name: "account_id", value: accountId),
        .init(name: "status_ids[]", value: statusId),
        .init(name: "comment", value: comment),
      ]
    default:
      return nil
    }
  }

  public var jsonValue: Encodable? {
    switch self {
    case .postStatus(let json):
      json
    case .editStatus(_, let json):
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
  public let quotedStatusId: String?

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

  public init(
    status: String,
    visibility: Visibility,
    inReplyToId: String? = nil,
    spoilerText: String? = nil,
    mediaIds: [String]? = nil,
    poll: PollData? = nil,
    language: String? = nil,
    mediaAttributes: [MediaAttribute]? = nil,
    quotedStatusId: String? = nil
  ) {
    self.status = status
    self.visibility = visibility
    self.inReplyToId = inReplyToId
    self.spoilerText = spoilerText
    self.mediaIds = mediaIds
    self.poll = poll
    self.language = language
    self.mediaAttributes = mediaAttributes
    self.quotedStatusId = quotedStatusId
  }
}
