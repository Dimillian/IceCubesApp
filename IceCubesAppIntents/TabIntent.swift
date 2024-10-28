import AppIntents
import Foundation

enum TabEnum: String, AppEnum, Sendable {
  case timeline, notifications, mentions, explore, messages, settings
  case trending, federated, local
  case profile
  case bookmarks
  case favorites
  case post
  case followedTags
  case lists
  case links

  static var typeDisplayName: LocalizedStringResource { "Tab" }

  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Tab"

  nonisolated static var caseDisplayRepresentations: [TabEnum: DisplayRepresentation] {
    [
      .timeline: .init(title: "Home Timeline"),
      .trending: .init(title: "Trending Timeline"),
      .federated: .init(title: "Federated Timeline"),
      .local: .init(title: "Local Timeline"),
      .notifications: .init(title: "Notifications"),
      .mentions: .init(title: "Mentions"),
      .explore: .init(title: "Explore & Trending"),
      .messages: .init(title: "Private Messages"),
      .settings: .init(title: "Settings"),
      .profile: .init(title: "Profile"),
      .bookmarks: .init(title: "Bookmarks"),
      .favorites: .init(title: "Favorites"),
      .followedTags: .init(title: "Followed Tags"),
      .lists: .init(title: "Lists"),
      .links: .init(title: "Trending Links"),
      .post: .init(title: "New post"),
    ]
  }

  var toAppTab: AppTab {
    switch self {
    case .timeline:
      .timeline
    case .notifications:
      .notifications
    case .mentions:
      .mentions
    case .explore:
      .explore
    case .messages:
      .messages
    case .settings:
      .settings
    case .trending:
      .trending
    case .federated:
      .federated
    case .local:
      .local
    case .profile:
      .profile
    case .bookmarks:
      .bookmarks
    case .favorites:
      .favorites
    case .post:
      .post
    case .followedTags:
      .followedTags
    case .lists:
      .lists
    case .links:
      .links
    }
  }
}

struct TabIntent: AppIntent {
  static let title: LocalizedStringResource = "Open on a tab"
  static let description: IntentDescription = "Open the app on a specific tab"
  static let openAppWhenRun: Bool = true

  @Parameter(title: "Selected tab")
  var tab: TabEnum

  @MainActor
  func perform() async throws -> some IntentResult {
    AppIntentService.shared.handledIntent = .init(intent: self)
    return .result()
  }
}
