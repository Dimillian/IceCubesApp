import DesignSystem
import Models
import Network
import SwiftUI
import Timeline
import WidgetKit

struct LatestPostsWidgetProvider: AppIntentTimelineProvider {
  func placeholder(in _: Context) -> PostsWidgetEntry {
    .init(date: Date(),
          title: "Home",
          statuses: [.placeholder()],
          images: [:])
  }

  func snapshot(for configuration: LatestPostsWidgetConfiguration, in context: Context) async -> PostsWidgetEntry {
    if let entry = await timeline(for: configuration, context: context).entries.first {
      return entry
    }
    return .init(date: Date(),
                 title: configuration.timeline.timeline.title,
                 statuses: [],
                 images: [:])
  }

  func timeline(for configuration: LatestPostsWidgetConfiguration, in context: Context) async -> Timeline<PostsWidgetEntry> {
    await timeline(for: configuration, context: context)
  }

  private func timeline(for configuration: LatestPostsWidgetConfiguration, context: Context) async -> Timeline<PostsWidgetEntry> {
    do {
      let statuses = await loadStatuses(for: configuration.timeline.timeline,
                                        account: configuration.account,
                                        widgetFamily: context.family)
      let images = try await loadImages(urls: statuses.map { $0.account.avatar })
      return Timeline(entries: [.init(date: Date(),
                                      title: configuration.timeline.timeline.title,
                                      statuses: statuses,
                                      images: images)], policy: .atEnd)
    } catch {
      return Timeline(entries: [.init(date: Date(),
                                      title: configuration.timeline.timeline.title,
                                      statuses: [],
                                      images: [:])],
                      policy: .atEnd)
    }
  }

  private func loadImages(urls: [URL]) async throws -> [URL: UIImage] {
    try await withThrowingTaskGroup(of: (URL, UIImage?).self) { group in
      for url in urls {
        group.addTask {
          let response = try await URLSession.shared.data(from: url)
          return (url, UIImage(data: response.0))
        }
      }

      var images: [URL: UIImage] = [:]

      for try await (url, image) in group {
        images[url] = image
      }

      return images
    }
  }
}

struct LatestPostsWidget: Widget {
  let kind: String = "LatestPostsWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind,
                           intent: LatestPostsWidgetConfiguration.self,
                           provider: LatestPostsWidgetProvider())
    { entry in
      PostsWidgetView(entry: entry)
        .containerBackground(Color("WidgetBackground").gradient, for: .widget)
    }
    .configurationDisplayName("Latest posts")
    .description("Show the latest post for the selected timeline")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
  }
}

#Preview(as: .systemMedium) {
  LatestPostsWidget()
} timeline: {
  PostsWidgetEntry(date: .now,
                   title: "Mastodon",
                   statuses: [.placeholder(), .placeholder(), .placeholder(), .placeholder()],
                   images: [:])
}
