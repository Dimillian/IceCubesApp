import Env
import Models
import Network
import StatusKit
import SwiftUI

@MainActor
@Observable
public class AccountStatusesListViewModel: StatusesFetcher {
  public enum Mode {
    case bookmarks, favorites

    var title: LocalizedStringKey {
      switch self {
      case .bookmarks:
        "accessibility.tabs.profile.picker.bookmarks"
      case .favorites:
        "accessibility.tabs.profile.picker.favorites"
      }
    }

    func endpoint(sinceId: String?) -> Endpoint {
      switch self {
      case .bookmarks:
        Accounts.bookmarks(sinceId: sinceId)
      case .favorites:
        Accounts.favorites(sinceId: sinceId)
      }
    }
  }

  let mode: Mode
  public var statusesState: StatusesState = .loading
  var statuses: [Status] = []
  var nextPage: LinkHandler?

  var client: Client?

  init(mode: Mode) {
    self.mode = mode
  }

  public func fetchNewestStatuses(pullToRefresh _: Bool) async {
    guard let client else { return }
    statusesState = .loading
    do {
      (statuses, nextPage) = try await client.getWithLink(endpoint: mode.endpoint(sinceId: nil))
      StatusDataControllerProvider.shared.updateDataControllers(for: statuses, client: client)
      statusesState = .display(statuses: statuses,
                               nextPageState: nextPage?.maxId != nil ? .hasNextPage : .none)
    } catch {
      statusesState = .error(error: error)
    }
  }

  public func fetchNextPage() async throws {
    guard let client, let nextId = nextPage?.maxId else { return }
    var newStatuses: [Status] = []
    (newStatuses, nextPage) = try await client.getWithLink(endpoint: mode.endpoint(sinceId: nextId))
    statuses.append(contentsOf: newStatuses)
    StatusDataControllerProvider.shared.updateDataControllers(for: statuses, client: client)
    statusesState = .display(statuses: statuses,
                             nextPageState: nextPage?.maxId != nil ? .hasNextPage : .none)
  }

  public func statusDidAppear(status _: Status) {}

  public func statusDidDisappear(status _: Status) {}
}
