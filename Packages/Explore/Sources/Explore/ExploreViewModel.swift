import Models
import Network
import Observation
import SwiftUI

@MainActor
@Observable class ExploreViewModel {
  enum SearchScope: String, CaseIterable {
    case all, people, hashtags, posts

    var localizedString: LocalizedStringKey {
      switch self {
      case .all:
        .init("explore.scope.all")
      case .people:
        .init("explore.scope.people")
      case .hashtags:
        .init("explore.scope.hashtags")
      case .posts:
        .init("explore.scope.posts")
      }
    }
  }

  var client: Client? {
    didSet {
      if oldValue != client {
        isLoaded = false
        results = [:]
        trendingTags = []
        trendingLinks = []
        trendingStatuses = []
        suggestedAccounts = []
      }
    }
  }

  var allSectionsEmpty: Bool {
    trendingLinks.isEmpty && trendingTags.isEmpty && trendingStatuses.isEmpty && suggestedAccounts.isEmpty
  }

  var searchQuery = "" {
    didSet {
      isSearching = true
    }
  }

  var results: [String: SearchResults] = [:]
  var isLoaded = false
  var isSearching = false
  var suggestedAccounts: [Account] = []
  var suggestedAccountsRelationShips: [Relationship] = []
  var trendingTags: [Tag] = []
  var trendingStatuses: [Status] = []
  var trendingLinks: [Card] = []
  var searchScope: SearchScope = .all
  var scrollToTopVisible: Bool = false
  var isSearchPresented: Bool = false

  init() {}

  func fetchTrending() async {
    guard let client else { return }
    do {
      let data = try await fetchTrendingsData(client: client)
      suggestedAccounts = data.suggestedAccounts
      trendingTags = data.trendingTags
      trendingStatuses = data.trendingStatuses
      trendingLinks = data.trendingLinks

      suggestedAccountsRelationShips = try await client.get(endpoint: Accounts.relationships(ids: suggestedAccounts.map(\.id)))
      withAnimation {
        isLoaded = true
      }
    } catch {
      isLoaded = true
    }
  }

  private struct TrendingData {
    let suggestedAccounts: [Account]
    let trendingTags: [Tag]
    let trendingStatuses: [Status]
    let trendingLinks: [Card]
  }

  private func fetchTrendingsData(client: Client) async throws -> TrendingData {
    async let suggestedAccounts: [Account] = client.get(endpoint: Accounts.suggestions)
    async let trendingTags: [Tag] = client.get(endpoint: Trends.tags)
    async let trendingStatuses: [Status] = client.get(endpoint: Trends.statuses(offset: nil))
    async let trendingLinks: [Card] = client.get(endpoint: Trends.links(offset: nil))
    return try await .init(suggestedAccounts: suggestedAccounts,
                           trendingTags: trendingTags,
                           trendingStatuses: trendingStatuses,
                           trendingLinks: trendingLinks)
  }

  func search() async {
    guard let client, !searchQuery.isEmpty else { return }
    do {
      try await Task.sleep(for: .milliseconds(250))
      var results: SearchResults = try await client.get(endpoint: Search.search(query: searchQuery,
                                                                                type: nil,
                                                                                offset: nil,
                                                                                following: nil),
                                                        forceVersion: .v2)
      let relationships: [Relationship] =
        try await client.get(endpoint: Accounts.relationships(ids: results.accounts.map(\.id)))
      results.relationships = relationships
      withAnimation {
        self.results[searchQuery] = results
        isSearching = false
      }
    } catch {
      isSearching = false
    }
  }
}
