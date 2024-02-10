import DesignSystem
import Models
import StatusKit
import SwiftUI
import Network

public struct TrendingLinksListView: View {
  @Environment(Theme.self) private var theme
  @Environment(Client.self) private var client

  @State private var links: [Card]
  @State private var isLoadingNextPage = false

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
      HStack {
        Spacer()
        ProgressView()
        Spacer()
      }
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
      #endif
      .task {
        defer {
          isLoadingNextPage = false
        }
        guard !isLoadingNextPage else { return }
        isLoadingNextPage = true
        do {
          let nextPage: [Card] = try await client.get(endpoint: Trends.links(offset: links.count))
          links.append(contentsOf: nextPage)
        } catch { }
      }
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
