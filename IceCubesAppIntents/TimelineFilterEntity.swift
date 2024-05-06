import AppAccount
import AppIntents
import Env
import Foundation
import Models
import Network
import Timeline

public struct TimelineFilterEntity: Identifiable, AppEntity {
  public var id: String { timeline.id }

  public let timeline: TimelineFilter

  public static let defaultQuery = DefaultTimelineEntityQuery()

  public static let typeDisplayRepresentation: TypeDisplayRepresentation = "TimelineFilter"

  public var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(timeline.title)")
  }
}

public struct DefaultTimelineEntityQuery: EntityQuery {
  public init() {}

  public func entities(for _: [TimelineFilter.ID]) async throws -> [TimelineFilterEntity] {
    [.home, .trending, .federated, .local].map { .init(timeline: $0) }
  }

  public func suggestedEntities() async throws -> [TimelineFilterEntity] {
    [.home, .trending, .federated, .local].map { .init(timeline: $0) }
  }

  public func defaultResult() async -> TimelineFilterEntity? {
    .init(timeline: .home)
  }
}
