import Foundation

public enum TimelineItem: Identifiable, Equatable, Sendable {
  case status(Status)
  case gap(TimelineGap)
  
  public var id: String {
    switch self {
    case .status(let status):
      return status.id
    case .gap(let gap):
      return gap.id
    }
  }
}

public struct TimelineGap: Identifiable, Equatable, Sendable {
  public let id: String
  public let sinceId: String
  public let maxId: String
  public var isLoading: Bool = false
  
  public init(sinceId: String?, maxId: String) {
    let sinceIdStr = sinceId ?? "start"
    self.id = "gap-\(sinceIdStr)-\(maxId)"
    self.sinceId = sinceId ?? ""
    self.maxId = maxId
  }
}
