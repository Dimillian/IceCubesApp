import SwiftUI
import Models
import Network

@MainActor
class ExploreViewModel: ObservableObject {
  var client: Client?
  
  enum Token: String, Identifiable {
    case user = "@user", tag = "#hasgtag"
    
    var id: String {
      rawValue
    }
  }
  
  @Published var tokens: [Token] = []
  @Published var suggestedToken: [Token] = []
  @Published var searchQuery = "" {
    didSet {
      if searchQuery.starts(with: "@") {
        suggestedToken = [.user]
      } else if searchQuery.starts(with: "#") {
        suggestedToken = [.tag]
      } else if tokens.isEmpty {
        suggestedToken = []
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
  
  func search() async {
    guard let client else { return }
    do {
      results[searchQuery] = try await client.get(endpoint: Search.search(query: searchQuery, type: nil, offset: nil), forceVersion: .v2)
    } catch { }
  }
}
