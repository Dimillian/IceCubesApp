import SwiftUI
import Models
import Network

@MainActor
class ExploreViewModel: ObservableObject {
  var client: Client?
  
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
}
