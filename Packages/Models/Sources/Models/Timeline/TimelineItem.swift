import Foundation

public enum TimelineItem: Identifiable, Equatable, Sendable {
  case status(Status)
  case gap(TimelineGap)

  public var status: Status? {
    switch self {
    case .status(let status):
      return status
    default:
      return nil
    }
  }

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
  public enum Direction: Sendable {
    case downward, upward
  }
  
  public let id: String
  public let sinceId: String
  public let maxId: String
  public var isLoading: Bool = false
  public let direction: Direction

  public init(sinceId: String?, maxId: String, direction: Direction) {
    let sinceIdStr = sinceId ?? "start"
    self.id = "gap-\(sinceIdStr)-\(maxId)-\(direction)"
    self.sinceId = sinceId ?? ""
    self.maxId = maxId
    self.direction = direction
  }
}
