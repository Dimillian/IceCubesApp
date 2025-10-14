import Combine
import Foundation
import Models
import NetworkClient
import Observation

@MainActor
@Observable public class CurrentInstance {
  public private(set) var instance: Instance?

  private var client: MastodonClient?

  public static let shared = CurrentInstance()

  private var version: Float {
    if let stringVersion = instance?.version {
      if stringVersion.utf8.count > 2 {
        return Float(stringVersion.prefix(3)) ?? 0
      } else {
        return Float(stringVersion.prefix(1)) ?? 0
      }
    }
    return 0
  }

  public var isFiltersSupported: Bool {
    version >= 4
  }

  public var isEditSupported: Bool {
    version >= 3.5
  }

  public var isEditAltTextSupported: Bool {
    version >= 4.1
  }

  public var isNotificationsFilterSupported: Bool {
    version >= 4.3
  }

  public var isLinkTimelineSupported: Bool {
    version >= 4.3
  }

  public var isGroupedNotificationsSupported: Bool {
    version >= 4.3
  }

  public var isQuoteSupported: Bool {
    instance?.apiVersions?.mastodon ?? 0 >= 7
  }

  public var canViewStatusQuotes: Bool {
    instance?.apiVersions?.mastodon ?? 0 >= 7
  }

  private init() {}

  public func setClient(client: MastodonClient) {
    self.client = client
  }

  public func fetchCurrentInstance() async {
    guard let client else { return }
    instance = try? await client.get(endpoint: Instances.instance, forceVersion: .v2)
  }
}
