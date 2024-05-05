import WidgetKit
import SwiftUI
import Network
import DesignSystem
import Models
import Timeline

struct LatestPostsWidgetProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> LatestPostWidgetEntry {
    .init(date: Date(), 
          configuration: IceCubesWidgetConfigurationIntent(),
          timeline: .home, 
          statuses: [.placeholder(), .placeholder()],
          images: [:])
  }
  
  func snapshot(for configuration: IceCubesWidgetConfigurationIntent, in context: Context) async -> LatestPostWidgetEntry {
    if let entry = await timeline(for: configuration, context: context).entries.first {
      return entry
    }
    return .init(date: Date(),
                 configuration: configuration,
                 timeline: .home, statuses: [],
                 images: [:])
  }
  
  func timeline(for configuration: IceCubesWidgetConfigurationIntent, in context: Context) async -> Timeline<LatestPostWidgetEntry> {
    await timeline(for: configuration, context: context)
  }
  
  private func timeline(for configuration: IceCubesWidgetConfigurationIntent, context: Context) async -> Timeline<LatestPostWidgetEntry> {
    guard let account = configuration.account, let timeline = configuration.timeline else {
      return Timeline(entries: [.init(date: Date(),
                                      configuration: configuration, 
                                      timeline: .home,
                                      statuses: [], 
                                      images: [:])],
               policy: .atEnd)
    }
    let client = Client(server: account.account.server, oauthToken: account.account.oauthToken)
    do {
      var statuses: [Status] = try await client.get(endpoint: timeline.timeline.endpoint(sinceId: nil,
                                                                                         maxId: nil,
                                                                                         minId: nil,
                                                                                         offset: nil))
      statuses = statuses.filter{ $0.reblog == nil && !$0.content.asRawText.isEmpty }
      switch context.family {
      case .systemMedium:
        if statuses.count >= 2 {
          statuses = statuses.prefix(upTo: 2).map{ $0 }
        }
      case .systemLarge:
        if statuses.count >= 5 {
          statuses = statuses.prefix(upTo: 5).map{ $0 }
        }
      case .systemExtraLarge:
        if statuses.count >= 8 {
          statuses = statuses.prefix(upTo: 8).map{ $0 }
        }
      default:
        break
      }
      let images = try await loadImages(urls: statuses.map{ $0.account.avatar })
      return Timeline(entries: [.init(date: Date(), configuration: configuration,
                                      timeline: timeline.timeline,
                                      statuses: statuses,
                                      images: images)], policy: .atEnd)
    } catch {
      return Timeline(entries: [.init(date: Date(), 
                                      configuration: configuration,
                                      timeline: .home,
                                      statuses: [],
                                      images: [:])], policy: .atEnd)
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

struct LatestPostWidgetEntry: TimelineEntry {
  let date: Date
  let configuration: IceCubesWidgetConfigurationIntent
  let timeline: TimelineFilter
  let statuses: [Status]
  let images: [URL: UIImage]
}

struct LatestPostsWidgetView : View {
  var entry: LatestPostsWidgetProvider.Entry
  
  @Environment(\.widgetFamily) var family
  @Environment(\.redactionReasons) var redacted
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      headerView
      ForEach(entry.statuses) { status in
        makeStatusView(status)
      }
      Spacer()
    }
    .frame(maxWidth: .infinity)
  }
  
  private var headerView: some View {
    HStack {
      Text(entry.timeline.title)
      Spacer()
      Image(systemName: "cube")
    }
    .font(.subheadline)
    .fontWeight(.bold)
    .foregroundStyle(Color("AccentColor"))
  }
  
  @ViewBuilder
  private func makeStatusView(_ status: Status) -> some View {
    if let url = URL(string: status.url ?? "") {
      Link(destination: url, label: {
        VStack(alignment: .leading, spacing: 4) {
          makeStatusHeaderView(status)
          Text(status.content.asRawText)
            .font(.body)
            .lineLimit(2)
        }
      })
    }
  }
  
  private func makeStatusHeaderView(_ status: Status) -> some View {
    HStack(spacing: 4) {
      if let image = entry.images[status.account.avatar] {
        Image(uiImage: image)
          .resizable()
          .frame(width: 16, height: 16)
          .clipShape(Circle())
      } else {
        Circle()
          .foregroundStyle(.secondary)
          .frame(width: 16, height: 16)
      }
      HStack(spacing: 0) {
        Text(status.account.safeDisplayName)
        Text(" @")
        Text(status.account.username)
        Spacer()
      }
      .font(.subheadline)
      .fontWeight(.semibold)
      .foregroundStyle(.secondary)
      .lineLimit(1)
    }
  }
}

struct LatestPostsWidget: Widget {
  let kind: String = "LatestPostsWidget"
  
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind,
                           intent: IceCubesWidgetConfigurationIntent.self,
                           provider: LatestPostsWidgetProvider()) { entry in
      LatestPostsWidgetView(entry: entry)
        .containerBackground(Color("WidgetBackground").gradient, for: .widget)
    }
    .configurationDisplayName("Latest posts")
    .description("Show the latest post for the selected timeline")
    .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
  }
}


#Preview(as: .systemMedium) {
  LatestPostsWidget()
} timeline: {
  LatestPostWidgetEntry(date: .now, 
                        configuration: .previewAccount,
                        timeline: .home,
                        statuses: [.placeholder(), .placeholder(), .placeholder(), .placeholder()],
                        images: [:])
}
