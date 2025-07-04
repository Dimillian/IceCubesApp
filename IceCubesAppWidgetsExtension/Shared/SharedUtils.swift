import AppAccount
import Foundation
import Models
import NetworkClient
import StatusKit
import Timeline
import UIKit
import WidgetKit

func loadStatuses(
  for timeline: TimelineFilter,
  account: AppAccountEntity,
  widgetFamily: WidgetFamily
) async -> [Status] {
  let client = MastodonClient(server: account.account.server, oauthToken: account.account.oauthToken)
  do {
    var statuses: [Status] = try await client.get(
      endpoint: timeline.endpoint(
        sinceId: nil,
        maxId: nil,
        minId: nil,
        offset: nil,
        limit: 6))
    statuses = statuses.filter { $0.reblog == nil && !$0.content.asRawText.isEmpty }
    switch widgetFamily {
    case .systemSmall, .systemMedium:
      if statuses.count >= 1 {
        statuses = statuses.prefix(upTo: 1).map { $0 }
      }
    case .systemLarge, .systemExtraLarge:
      if statuses.count >= 5 {
        statuses = statuses.prefix(upTo: 5).map { $0 }
      }
    default:
      break
    }
    return statuses
  } catch {
    return []
  }
}

func loadImages(urls: [URL]) async throws -> [URL: UIImage] {
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
