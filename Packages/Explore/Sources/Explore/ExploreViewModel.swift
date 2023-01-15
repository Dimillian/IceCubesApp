import SwiftUI
import Models
import Network
import Combine

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
  
  enum Token: String, Identifiable {
    case user = "@user"
    case statuses = "@posts"
    case tag = "#hashtag"
    
    var id: String {
      rawValue
    }
    
    var apiType: String {
      switch self {
      case .user:
        return "accounts"
      case .tag:
        return "hashtags"
      case .statuses:
        return "statuses"
      }
    }
  }
  
  @Published var tokens: [Token] = []
  @Published var suggestedToken: [Token] = []
  @Published var searchQuery = ""
  @Published var results: [String: SearchResults] = [:]
  @Published var isLoaded = false
  @Published var suggestedAccounts: [Account] = []
  @Published var suggestedAccountsRelationShips: [Relationshionship] = []
  @Published var trendingTags: [Tag] = []
  @Published var trendingStatuses: [Status] = []
  @Published var trendingLinks: [Card] = []
  
  private var searchTask: Task<Void, Never>?
  private var cancellables = Set<AnyCancellable>()

  init() {
    $searchQuery
      .removeDuplicates()
      .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
      .sink(receiveValue: { [weak self] newValue in
        guard let self else { return }

        if self.searchQuery.starts(with: "@") {
          self.suggestedToken = [.user, .statuses]
        } else if self.searchQuery.starts(with: "#") {
          self.suggestedToken = [.tag]
        } else {
          self.suggestedToken = []
        }

        self.search()
      })
      .store(in: &cancellables)
  }
  
  func fetchTrending() async {
    guard let client else { return }
    do {
      let data = try await fetchTrendingsData(client: client)
      self.suggestedAccounts = data.suggestedAccounts
      self.trendingTags = data.trendingTags
      self.trendingStatuses = data.trendingStatuses
      self.trendingLinks = data.trendingLinks
      
      self.suggestedAccountsRelationShips = try await client.get(endpoint: Accounts.relationships(ids: self.suggestedAccounts.map{ $0.id }))
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
    searchTask?.cancel()
    searchTask = nil
    searchTask = Task {
      guard let client else { return }
      do {
        let apiType = tokens.first?.apiType
        var results: SearchResults = try await client.get(endpoint: Search.search(query: searchQuery,
                                                                                  type: apiType,
                                                                                  offset: nil,
                                                                                  following: nil),
                                                          forceVersion: .v2)
        let relationships: [Relationshionship] =
          try await client.get(endpoint: Accounts.relationships(ids: results.accounts.map{ $0.id }))
        results.relationships = relationships
        self.results[searchQuery] = results
      } catch { }
    }
  }
}
