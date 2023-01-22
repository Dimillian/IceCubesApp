import Models
import Foundation

public struct Digest: Identifiable {
  public let generatedAt: String
  public let hoursSince: Int
  public let totalStatuses: Int

  public var id: String {
    "\(generatedAt)-\(hoursSince)"
  }
}

public extension Status {
  func didInteract() -> Bool {
    var postInfo: AnyStatus = self
    if let rebloggedStatus = reblog {
      postInfo = rebloggedStatus
    }
    return (postInfo.reblogged ?? false) || (postInfo.favourited ?? false) || (postInfo.bookmarked ?? false)
  }

  func isRelevant() -> Bool {
    var postInfo: AnyStatus = self
    if let rebloggedStatus = reblog {
      postInfo = rebloggedStatus
    }
    return postInfo.repliesCount > 0 || postInfo.reblogsCount > 0 || postInfo.favouritesCount > 0
  }

  func popularity() -> Double {
    var postInfo: AnyStatus = self
    if let rebloggedStatus = reblog {
      postInfo = rebloggedStatus
    }
    let criterias = [
      Double(postInfo.reblogsCount + 1),
      Double(postInfo.favouritesCount + 1),
      Double(postInfo.repliesCount + 1)
    ]
    var weight = Double(0)
    if postInfo.account.followersCount > 0 {
      weight = 1 / sqrt(Double(postInfo.account.followersCount))
    }
    return pow(criterias.reduce(Double(1), {x, y in x * y}), 1/Double(criterias.count)) * weight
  }
}
