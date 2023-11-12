import Foundation

public enum Polls: Endpoint {
  case poll(id: String)
  case vote(id: String, votes: [Int])

  public func path() -> String {
    switch self {
    case let .poll(id):
      "polls/\(id)"
    case let .vote(id, _):
      "polls/\(id)/votes"
    }
  }

  public func queryItems() -> [URLQueryItem]? {
    switch self {
    case let .vote(_, votes):
      var params: [URLQueryItem] = []
      for vote in votes {
        params.append(.init(name: "choices[]", value: "\(vote)"))
      }
      return params

    default:
      return nil
    }
  }
}
