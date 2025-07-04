import DesignSystem
import Models
import NetworkClient
import StatusKit
import SwiftUI

public struct TrendingLinksListView: View {
  @Environment(Theme.self) private var theme
  @Environment(MastodonClient.self) private var client

  @State private var links: [Card]

  public init(cards: [Card]) {
    _links = .init(initialValue: cards)
  }

  public var body: some View {
    List {
      ForEach(links) { card in
        StatusRowCardView(card: card)
          .environment(\.isCompact, true)
          #if !os(visionOS)
            .listRowBackground(theme.primaryBackgroundColor)
          #endif
          .padding(.vertical, 8)
      }
      NextPageView {
        let nextPage: [Card] = try await client.get(endpoint: Trends.links(offset: links.count))
        links.append(contentsOf: nextPage)
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
    #if os(visionOS)
      .listStyle(.insetGrouped)
    #else
      .listStyle(.plain)
    #endif
    .refreshable {
      do {
        links = try await client.get(endpoint: Trends.links(offset: nil))
      } catch {}
    }
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
    #endif
    .navigationTitle("explore.section.trending.links")
    .navigationBarTitleDisplayMode(.inline)
  }
}
