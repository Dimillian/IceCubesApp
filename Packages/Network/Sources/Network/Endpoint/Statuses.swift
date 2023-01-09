import Foundation
import Models

public enum Statuses: Endpoint {
  case postStatus(status: String,
                  inReplyTo: String?,
                  mediaIds: [String]?,
                  spoilerText: String?,
                  visibility: Visibility)
  case editStatus(id: String,
                  status: String,
                  mediaIds: [String]?,
                  spoilerText: String?,
                  visibility: Visibility)
  case status(id: String)
  case context(id: String)
  case favourite(id: String)
  case unfavourite(id: String)
  case reblog(id: String)
  case unreblog(id: String)
  case rebloggedBy(id: String, maxId: String?)
  case favouritedBy(id: String, maxId: String?)
  case pin(id: String)
  case unpin(id: String)
  case bookmark(id: String)
  case unbookmark(id: String)
  
  public func path() -> String {
    switch self {
    case .postStatus:
      return "statuses"
    case .status(let id):
      return "statuses/\(id)"
    case .editStatus(let id, _, _, _, _):
      return "statuses/\(id)"
    case .context(let id):
      return "statuses/\(id)/context"
    case .favourite(let id):
      return "statuses/\(id)/favourite"
    case .unfavourite(let id):
      return "statuses/\(id)/unfavourite"
    case .reblog(let id):
      return "statuses/\(id)/reblog"
    case .unreblog(let id):
      return "statuses/\(id)/unreblog"
    case .rebloggedBy(let id, _):
      return "statuses/\(id)/reblogged_by"
    case .favouritedBy(let id, _):
      return "statuses/\(id)/favourited_by"
    case let .pin(id):
      return "statuses/\(id)/pin"
    case let .unpin(id):
      return "statuses/\(id)/unpin"
    case let .bookmark(id):
      return "statuses/\(id)/bookmark"
    case let .unbookmark(id):
      return "statuses/\(id)/unbookmark"
    }
  }
  
  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .postStatus(status, inReplyTo, mediaIds, spoilerText, visibility):
      var params: [URLQueryItem] = [.init(name: "status", value: status),
                                    .init(name: "visibility", value: visibility.rawValue)]
      if let inReplyTo {
        params.append(.init(name: "in_reply_to_id", value: inReplyTo))
      }
      if let mediaIds {
        for mediaId in mediaIds {
          params.append(.init(name: "media_ids[]", value: mediaId))
        }
      }
      if let spoilerText {
        params.append(.init(name: "spoiler_text", value: spoilerText))
      }
      return params
    case let .editStatus(_, status, mediaIds, spoilerText, visibility):
      var params: [URLQueryItem] = [.init(name: "status", value: status),
                                    .init(name: "visibility", value: visibility.rawValue)]
      if let mediaIds {
        for mediaId in mediaIds {
          params.append(.init(name: "media_ids[]", value: mediaId))
        }
      }
      if let spoilerText {
        params.append(.init(name: "spoiler_text", value: spoilerText))
      }
      return params
    case let .rebloggedBy(_, maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    case let .favouritedBy(_, maxId):
      return makePaginationParam(sinceId: nil, maxId: maxId, mindId: nil)
    default:
      return nil
    }
  }
}
