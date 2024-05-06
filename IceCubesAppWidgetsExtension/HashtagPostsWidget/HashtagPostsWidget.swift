import DesignSystem
import Models
import Network
import SwiftUI
import Timeline
import WidgetKit

struct HashtagPostsWidgetProvider: AppIntentTimelineProvider {
  func placeholder(in _: Context) -> PostsWidgetEntry {
    .init(date: Date(),
          title: "#Mastodon",
          statuses: [.placeholder()],
          images: [:])
  }

  func snapshot(for configuration: HashtagPostsWidgetConfiguration, in context: Context) async -> PostsWidgetEntry {
    if let entry = await timeline(for: configuration, context: context).entries.first {
      return entry
    }
    return .init(date: Date(),
                 title: "#Mastodon",
                 statuses: [],
                 images: [:])
  }

  func timeline(for configuration: HashtagPostsWidgetConfiguration, in context: Context) async -> Timeline<PostsWidgetEntry> {
    await timeline(for: configuration, context: context)
  }

  private func timeline(for configuration: HashtagPostsWidgetConfiguration, context: Context) async -> Timeline<PostsWidgetEntry> {
    do {
      let timeline: TimelineFilter = .hashtag(tag: configuration.hashgtag, accountId: nil)
      let statuses = await loadStatuses(for: timeline,
                                        account: configuration.account,
                                        widgetFamily: context.family)
      let images = try await loadImages(urls: statuses.map { $0.account.avatar })
      return Timeline(entries: [.init(date: Date(),
                                      title: timeline.title,
                                      statuses: statuses,
                                      images: images)], policy: .atEnd)
    } catch {
      return Timeline(entries: [.init(date: Date(),
                                      title: "#Mastodon",
                                      statuses: [],
                                      images: [:])],
                      policy: .atEnd)
    }
  }
}

struct HashtagPostsWidget: Widget {
  let kind: String = "HashtagPostsWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind,
                           intent: HashtagPostsWidgetConfiguration.self,
                           provider: HashtagPostsWidgetProvider())
    { entry in
      PostsWidgetView(entry: entry)
        .containerBackground(Color("WidgetBackground").gradient, for: .widget)
    }
    .configurationDisplayName("Hashtag timeline")
    .description("Show the latest post for the selected hashtag")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
  }
}

#Preview(as: .systemMedium) {
  HashtagPostsWidget()
} timeline: {
  PostsWidgetEntry(date: .now,
                   title: "#Mastodon",
                   statuses: [.placeholder(), .placeholder(), .placeholder(), .placeholder()],
                   images: [:])
}
