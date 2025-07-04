import Models
import NetworkClient
import Observation
import StatusKit
import SwiftUI

@MainActor
@Observable
public class AccountTabManager {
  private let allTabs: [any AccountTabProtocol] = [
    StatusesTab(),
    RepliesTab(),
    BoostsTab(),
    MediaTab(),
    FavoritesTab(),
    BookmarksTab(),
  ]

  public let accountId: String
  public let client: MastodonClient
  public var isCurrentUser: Bool

  public var availableTabs: [any AccountTabProtocol] {
    allTabs.filter { tab in
      isCurrentUser ? tab.isAvailableForCurrentUser : tab.isAvailableForOtherUsers
    }
  }

  public var selectedTab: any AccountTabProtocol {
    didSet {
      if selectedTab.id != oldValue.id {
        tabDidChange()
      }
    }
  }

  public var selectedTabId: String {
    selectedTab.id
  }

  private var currentFetcher: (any StatusesFetcher)?
  private var fetchers: [String: any StatusesFetcher] = [:]

  public init(accountId: String, client: MastodonClient, isCurrentUser: Bool) {
    self.accountId = accountId
    self.client = client
    self.isCurrentUser = isCurrentUser
    let tabs = allTabs.filter { tab in
      isCurrentUser ? tab.isAvailableForCurrentUser : tab.isAvailableForOtherUsers
    }
    self.selectedTab = tabs.first ?? StatusesTab()
  }

  public func getFetcher(for tab: any AccountTabProtocol) -> any StatusesFetcher {
    if let existingFetcher = fetchers[tab.id] {
      return existingFetcher
    }

    let fetcher = tab.createFetcher(
      accountId: accountId, client: client, isCurrentUser: isCurrentUser)
    fetchers[tab.id] = fetcher
    return fetcher
  }

  public var currentTabFetcher: any StatusesFetcher {
    if let fetcher = currentFetcher {
      return fetcher
    }

    let fetcher = getFetcher(for: selectedTab)
    currentFetcher = fetcher
    return fetcher
  }

  private func tabDidChange() {
    currentFetcher = getFetcher(for: selectedTab)

    Task {
      await currentTabFetcher.fetchNewestStatuses(pullToRefresh: false)
    }
  }

  public func refreshCurrentTab() async {
    await currentTabFetcher.fetchNewestStatuses(pullToRefresh: true)
  }
}
