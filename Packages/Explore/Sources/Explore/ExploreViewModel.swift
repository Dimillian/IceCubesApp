import SwiftUI
import Models
import Network

@MainActor
class ExploreViewModel: ObservableObject {
  var client: Client?
  
  enum Token: String, Identifiable {
    case user = "@user"
    case statuses = "@posts"
    case tag = "#hasgtag"
    
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
  @Published var searchQuery = "" {
    didSet {
      if searchQuery.starts(with: "@") {
        suggestedToken = [.user, .statuses]
      } else if searchQuery.starts(with: "#") {
        suggestedToken = [.tag]
      } else if !tokens.isEmpty {
        suggestedToken = []
        search()
      } else {
        search()
      }
    }
  }
  @Published var results: [String: SearchResults] = [:]
  @Published var isLoaded = false
  @Published var suggestedAccounts: [Account] = []
  @Published var suggestedAccountsRelationShips: [Relationshionship] = []
  @Published var trendingTags: [Tag] = []
  @Published var trendingStatuses: [Status] = []
  @Published var trendingLinks: [Card] = []
  
  private var searchTask: Task<Void, Never>?
  
  func fetchTrending() async {
    guard let client else { return }
    do {
      isLoaded = false
      
      async let suggestedAccounts: [Account] = client.get(endpoint: Accounts.suggestions)
      async let trendingTags: [Tag] = client.get(endpoint: Trends.tags)
      async let trendingStatuses: [Status] = client.get(endpoint: Trends.statuses)
      async let trendingLinks: [Card] = client.get(endpoint: Trends.links)
      
      self.suggestedAccounts = try await suggestedAccounts
      self.trendingTags = try await trendingTags
      self.trendingStatuses = try await trendingStatuses
      self.trendingLinks = try await trendingLinks
      
      self.suggestedAccountsRelationShips = try await client.get(endpoint: Accounts.relationships(ids: self.suggestedAccounts.map{ $0.id }))
      
      isLoaded = true
    } catch { }
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
                                                                                  offset: nil),
                                                          forceVersion: .v2)
        let relationships: [Relationshionship] =
          try await client.get(endpoint: Accounts.relationships(ids: results.accounts.map{ $0.id }))
        results.relationships = relationships
        self.results[searchQuery] = results
      } catch { }
    }
  }
}
