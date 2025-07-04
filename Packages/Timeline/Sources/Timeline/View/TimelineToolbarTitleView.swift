import SwiftUI
import NetworkClient

struct TimelineToolbarTitleView: ToolbarContent {
  @Environment(MastodonClient.self) private var client
  
  @Binding var timeline: TimelineFilter
  let canFilterTimeline: Bool
  
  var body: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      VStack(alignment: .center) {
        switch timeline {
        case let .remoteLocal(_, filter):
          Text(filter.localizedTitle())
            .font(.headline)
          Text(timeline.localizedTitle())
            .font(.caption)
            .foregroundStyle(.secondary)
        case let .link(url, _):
          Text(timeline.localizedTitle())
            .font(.headline)
          Text(url.host() ?? url.absoluteString)
            .font(.caption)
            .foregroundStyle(.secondary)
        default:
          Text(timeline.localizedTitle())
            .font(.headline)
          Text(client.server)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .accessibilityRepresentation {
        switch timeline {
        case let .remoteLocal(_, filter):
          if canFilterTimeline {
            Menu(filter.localizedTitle()) {}
          } else {
            Text(filter.localizedTitle())
          }
        default:
          if canFilterTimeline {
            Menu(timeline.localizedTitle()) {}
          } else {
            Text(timeline.localizedTitle())
          }
        }
      }
      .accessibilityAddTraits(.isHeader)
      .accessibilityRemoveTraits(.isButton)
      .accessibilityRespondsToUserInteraction(canFilterTimeline)
    }
  }
}
