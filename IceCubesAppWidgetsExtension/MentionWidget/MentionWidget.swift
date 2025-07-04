import DesignSystem
import Models
import NetworkClient
import SwiftUI
import Timeline
import WidgetKit

struct MentionsWidgetProvider: AppIntentTimelineProvider {
  func placeholder(in _: Context) -> PostsWidgetEntry {
    .init(
      date: Date(),
      title: "Mentions",
      statuses: [.placeholder()],
      images: [:])
  }

  func snapshot(for configuration: MentionsWidgetConfiguration, in context: Context) async
    -> PostsWidgetEntry
  {
    if let entry = await timeline(for: configuration, context: context).entries.first {
      return entry
    }
    return .init(
      date: Date(),
      title: "Mentions",
      statuses: [],
      images: [:])
  }

  func timeline(for configuration: MentionsWidgetConfiguration, in context: Context) async
    -> Timeline<PostsWidgetEntry>
  {
    await timeline(for: configuration, context: context)
  }

  private func timeline(for configuration: MentionsWidgetConfiguration, context _: Context) async
    -> Timeline<PostsWidgetEntry>
  {
    do {
      guard let account = configuration.account else {
        return Timeline(
          entries: [
            .init(
              date: Date(),
              title: "Mentions",
              statuses: [],
              images: [:])
          ],
          policy: .atEnd)
      }
      let client = MastodonClient(
        server: account.account.server,
        oauthToken: account.account.oauthToken)
      var excludedTypes = Models.Notification.NotificationType.allCases
      excludedTypes.removeAll(where: { $0 == .mention })
      let notifications: [Models.Notification] =
        try await client.get(
          endpoint: Notifications.notifications(
            minId: nil,
            maxId: nil,
            types: excludedTypes.map(\.rawValue),
            limit: 5))
      let statuses = notifications.compactMap { $0.status }
      let images = try await loadImages(urls: statuses.map { $0.account.avatar })
      return Timeline(
        entries: [
          .init(
            date: Date(),
            title: "Mentions",
            statuses: statuses,
            images: images)
        ], policy: .atEnd)
    } catch {
      return Timeline(
        entries: [
          .init(
            date: Date(),
            title: "Mentions",
            statuses: [],
            images: [:])
        ],
        policy: .atEnd)
    }
  }
}

struct MentionsWidget: Widget {
  let kind: String = "MentionsWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: MentionsWidgetConfiguration.self,
      provider: MentionsWidgetProvider()
    ) { entry in
      PostsWidgetView(entry: entry)
        .containerBackground(Color("WidgetBackground").gradient, for: .widget)
    }
    .configurationDisplayName("Mentions")
    .description("Show the latest mentions for the selected account.")
    .supportedFamilies([.systemLarge, .systemExtraLarge])
  }
}

#Preview(as: .systemMedium) {
  MentionsWidget()
} timeline: {
  PostsWidgetEntry(
    date: .now,
    title: "Mentions",
    statuses: [.placeholder(), .placeholder(), .placeholder(), .placeholder()],
    images: [:])
}
