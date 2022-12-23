import SwiftUI
import Models
import Network

@MainActor
class ExploreViewModel: ObservableObject {
  var client: Client?
  
  @Published var trendingTags: [Tag] = []
  @Published var trendingStatuses: [Status] = []
  @Published var trendingLinks: [Card] = []
  
  func fetchTrending() async {
    guard let client else { return }
    do {
      async let trendingTags: [Tag] = client.get(endpoint: Trends.tags)
      async let trendingStatuses: [Status] = client.get(endpoint: Trends.statuses)
      async let trendingLinks: [Card] = client.get(endpoint: Trends.links)
      
      self.trendingTags = try await trendingTags
      self.trendingStatuses = try await trendingStatuses
      self.trendingLinks = try await trendingLinks
    } catch { }
  }
}
