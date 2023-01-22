import Combine
import Models
import Network
import SwiftUI

@MainActor
class ExploreViewModel: ObservableObject {
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

  @Published var searchQuery = "" {
    didSet {
      isSearching = true
    }
  }

  @Published var results: [String: SearchResults] = [:]
  @Published var isLoaded = false
  @Published var isSearching = false
  @Published var suggestedAccounts: [Account] = []
  @Published var suggestedAccountsRelationShips: [Relationship] = []
  @Published var trendingTags: [Tag] = []
  @Published var trendingStatuses: [Status] = []
  @Published var trendingLinks: [Card] = []

  private var searchTask: Task<Void, Never>?
  private var cancellables = Set<AnyCancellable>()

  init() {
    $searchQuery
      .removeDuplicates()
      .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
      .sink(receiveValue: { [weak self] _ in
        self?.search()
      })
      .store(in: &cancellables)
  }

  func fetchTrending() async {
    guard let client else { return }
    do {
      let data = try await fetchTrendingsData(client: client)
      suggestedAccounts = data.suggestedAccounts
      trendingTags = data.trendingTags
      trendingStatuses = data.trendingStatuses
      trendingLinks = data.trendingLinks

      suggestedAccountsRelationShips = try await client.get(endpoint: Accounts.relationships(ids: suggestedAccounts.map { $0.id }))
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
    async let trendingLinks: [Card] = client.get(endpoint: Trends.links)
    return try await .init(suggestedAccounts: suggestedAccounts,
                           trendingTags: trendingTags,
                           trendingStatuses: trendingStatuses,
                           trendingLinks: trendingLinks)
  }

  func search() {
    guard !searchQuery.isEmpty else { return }
    isSearching = true
    searchTask?.cancel()
    searchTask = nil
    searchTask = Task {
      guard let client else { return }
      do {
        var results: SearchResults = try await client.get(endpoint: Search.search(query: searchQuery,
                                                                                  type: nil,
                                                                                  offset: nil,
                                                                                  following: nil),
                                                          forceVersion: .v2)
        let relationships: [Relationship] =
          try await client.get(endpoint: Accounts.relationships(ids: results.accounts.map { $0.id }))
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
}
