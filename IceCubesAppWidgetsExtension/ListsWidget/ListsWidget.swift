import DesignSystem
import Models
import NetworkClient
import SwiftUI
import Timeline
import WidgetKit

struct ListsWidgetProvider: AppIntentTimelineProvider {
  func placeholder(in _: Context) -> PostsWidgetEntry {
    .init(
      date: Date(),
      title: "List name",
      statuses: [.placeholder()],
      images: [:])
  }

  func snapshot(for configuration: ListsWidgetConfiguration, in context: Context) async
    -> PostsWidgetEntry
  {
    if let entry = await timeline(for: configuration, context: context).entries.first {
      return entry
    }
    return .init(
      date: Date(),
      title: "List name",
      statuses: [],
      images: [:])
  }

  func timeline(for configuration: ListsWidgetConfiguration, in context: Context) async -> Timeline<
    PostsWidgetEntry
  > {
    await timeline(for: configuration, context: context)
  }

  private func timeline(for configuration: ListsWidgetConfiguration, context: Context) async
    -> Timeline<PostsWidgetEntry>
  {
    do {
      guard let account = configuration.account, let timeline = configuration.timeline else {
        return Timeline(
          entries: [
            .init(
              date: Date(),
              title: "List name",
              statuses: [],
              images: [:])
          ],
          policy: .atEnd)
      }
      let filter: TimelineFilter = .list(list: timeline.list)
      let statuses = await loadStatuses(
        for: filter,
        account: account,
        widgetFamily: context.family)
      let images = try await loadImages(urls: statuses.map { $0.account.avatar })
      return Timeline(
        entries: [
          .init(
            date: Date(),
            title: filter.title,
            statuses: statuses,
            images: images)
        ], policy: .atEnd)
    } catch {
      return Timeline(
        entries: [
          .init(
            date: Date(),
            title: "List name",
            statuses: [],
            images: [:])
        ],
        policy: .atEnd)
    }
  }
}

struct ListsPostWidget: Widget {
  let kind: String = "ListsPostWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: ListsWidgetConfiguration.self,
      provider: ListsWidgetProvider()
    ) { entry in
      PostsWidgetView(entry: entry)
        .containerBackground(Color("WidgetBackground").gradient, for: .widget)
    }
    .configurationDisplayName("List timeline")
    .description("Show the latest post for the selected list")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
  }
}

#Preview(as: .systemMedium) {
  ListsPostWidget()
} timeline: {
  PostsWidgetEntry(
    date: .now,
    title: "List name",
    statuses: [.placeholder(), .placeholder(), .placeholder(), .placeholder()],
    images: [:])
}
