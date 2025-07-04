import DesignSystem
import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

@MainActor
public struct AccountStatusesListView: View {
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

  @Environment(Theme.self) private var theme
  @Environment(MastodonClient.self) private var client
  @Environment(RouterPath.self) private var routerPath

  let mode: Mode
  @State private var isLoaded = false
  @State private var fetcher: AccountStatusesFetcher

  public init(mode: Mode) {
    self.mode = mode
    _fetcher = .init(initialValue: AccountStatusesFetcher(mode: mode))
  }

  public var body: some View {
    List {
      StatusesListView(fetcher: fetcher, client: client, routerPath: routerPath)
        .listSectionSeparator(.hidden, edges: .top)
    }
    .listStyle(.plain)
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
    #endif
    .navigationTitle(mode.title)
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      await fetcher.fetchNewestStatuses(pullToRefresh: true)
    }
    .task {
      guard !isLoaded else { return }
      fetcher.client = client
      await fetcher.fetchNewestStatuses(pullToRefresh: false)
      isLoaded = true
    }
    .onChange(of: client.id) { _, _ in
      isLoaded = false
      fetcher = AccountStatusesFetcher(mode: mode)
      fetcher.client = client
      Task {
        await fetcher.fetchNewestStatuses(pullToRefresh: false)
        isLoaded = true
      }
    }
  }
}
