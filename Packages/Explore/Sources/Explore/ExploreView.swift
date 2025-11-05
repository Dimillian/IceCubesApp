import Account
import DesignSystem
import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

@MainActor
public struct ExploreView: View {
  @Environment(Theme.self) private var theme
  @Environment(MastodonClient.self) private var client
  @Environment(RouterPath.self) private var routerPath

  @State private var searchQuery = ""
  @State private var searchScope: SearchScope = .all
  @State private var isSearchPresented = false
  @State private var isLoaded = false
  @State private var isSearching = false
  @State private var results: [String: SearchResults] = [:]
  @State private var suggestedAccounts: [Account] = []
  @State private var suggestedAccountsRelationShips: [Relationship] = []
  @State private var trendingTags: [Tag] = []
  @State private var trendingStatuses: [Status] = []
  @State private var trendingLinks: [Card] = []
  @State private var scrollToTopVisible = false

  private var allSectionsEmpty: Bool {
    trendingLinks.isEmpty && trendingTags.isEmpty && trendingStatuses.isEmpty
      && suggestedAccounts.isEmpty
  }

  public init() {}

  public var body: some View {
    ScrollViewReader { proxy in
      List {
        scrollToTopView
        if !isLoaded {
          QuickAccessView(
            trendingLinks: trendingLinks,
            suggestedAccounts: suggestedAccounts,
            trendingTags: trendingTags
          )
          loadingView
        } else if !searchQuery.isEmpty {
          if let results = results[searchQuery] {
            if results.isEmpty, !isSearching {
              PlaceholderView(
                iconName: "magnifyingglass",
                title: "explore.search.empty.title",
                message: "explore.search.empty.message"
              )
              .listRowBackground(theme.secondaryBackgroundColor)
              .listRowSeparator(.hidden)
            } else {
              SearchResultsView(
                results: results,
                searchScope: searchScope,
                onNextPage: fetchNextPage
              )
            }
          } else {
            HStack {
              Spacer()
              ProgressView()
              Spacer()
            }
            #if !os(visionOS)
              .listRowBackground(theme.secondaryBackgroundColor)
            #endif
            .listRowSeparator(.hidden)
            .id(UUID())
          }
        } else if allSectionsEmpty {
          PlaceholderView(
            iconName: "magnifyingglass",
            title: "explore.search.title",
            message: "explore.search.message-\(client.server)"
          )
          #if !os(visionOS)
            .listRowBackground(theme.secondaryBackgroundColor)
          #endif
          .listRowSeparator(.hidden)
        } else {
          QuickAccessView(
            trendingLinks: trendingLinks,
            suggestedAccounts: suggestedAccounts,
            trendingTags: trendingTags
          )
          .padding(.bottom, 4)

          if !trendingTags.isEmpty {
            TrendingTagsSection(trendingTags: trendingTags)
          }
          if !suggestedAccounts.isEmpty {
            SuggestedAccountsSection(
              suggestedAccounts: suggestedAccounts,
              suggestedAccountsRelationShips: suggestedAccountsRelationShips
            )
          }
          if !trendingStatuses.isEmpty {
            TrendingPostsSection(trendingStatuses: trendingStatuses)
          }
          if !trendingLinks.isEmpty {
            TrendingLinksSection(trendingLinks: trendingLinks)
          }
        }
      }
      .environment(\.defaultMinListRowHeight, .scrollToViewHeight)
      .task {
        await fetchTrending()
      }
      .refreshable {
        Task {
          SoundEffectManager.shared.playSound(.pull)
          HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.3))
          await fetchTrending()
          HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.7))
          SoundEffectManager.shared.playSound(.refresh)
        }
      }
      .listStyle(.grouped)
      #if !os(visionOS)
        .scrollContentBackground(.hidden)
        .background(theme.secondaryBackgroundColor.edgesIgnoringSafeArea(.all))
      #endif
      .navigationTitle("explore.navigation-title")
      .navigationBarTitleDisplayMode(.inline)
      .searchable(
        text: $searchQuery,
        isPresented: $isSearchPresented,
        placement: .navigationBarDrawer(displayMode: .always),
        prompt: Text("explore.search.prompt")
      )
      .searchScopes($searchScope) {
        ForEach(SearchScope.allCases, id: \.self) { scope in
          Text(scope.localizedString)
        }
      }
      .task(id: searchQuery) {
        await search()
      }
    }
  }

  private var loadingView: some View {
    ForEach(Status.placeholders()) { status in
      StatusRowExternalView(
        viewModel: .init(status: status, client: client, routerPath: routerPath)
      )
      .padding(.vertical, 8)
      .redacted(reason: .placeholder)
      .allowsHitTesting(false)
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
  }

  private var scrollToTopView: some View {
    ScrollToView()
      .frame(height: .scrollToViewHeight)
      .onAppear {
        scrollToTopVisible = true
      }
      .onDisappear {
        scrollToTopVisible = false
      }
  }
}

extension ExploreView {
  private func fetchTrending() async {
    do {
      let data = try await fetchTrendingsData()
      suggestedAccounts = data.suggestedAccounts
      trendingTags = data.trendingTags
      trendingStatuses = data.trendingStatuses
      trendingLinks = data.trendingLinks

      suggestedAccountsRelationShips = try await client.get(
        endpoint: Accounts.relationships(ids: suggestedAccounts.map(\.id)))
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

  private func fetchTrendingsData() async throws -> TrendingData {
    async let suggestedAccounts: [Account] = client.get(endpoint: Accounts.suggestions)
    async let trendingTags: [Tag] = client.get(endpoint: Trends.tags)
    async let trendingStatuses: [Status] = client.get(endpoint: Trends.statuses(offset: nil))
    async let trendingLinks: [Card] = client.get(endpoint: Trends.links(offset: nil))
    return try await .init(
      suggestedAccounts: suggestedAccounts,
      trendingTags: trendingTags,
      trendingStatuses: trendingStatuses,
      trendingLinks: trendingLinks)
  }

  private func search() async {
    guard !searchQuery.isEmpty else { return }
    isSearching = true
    do {
      try await Task.sleep(for: .milliseconds(250))
      var results: SearchResults = try await client.get(
        endpoint: Search.search(
          query: searchQuery,
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

  private func fetchNextPage(of type: Search.EntityType) async {
    guard !searchQuery.isEmpty,
      let results = results[searchQuery]
    else { return }
    do {
      let offset =
        switch type {
        case .accounts:
          results.accounts.count
        case .hashtags:
          results.hashtags.count
        case .statuses:
          results.statuses.count
        }

      var newPageResults: SearchResults = try await client.get(
        endpoint: Search.search(
          query: searchQuery,
          type: type,
          offset: offset,
          following: nil),
        forceVersion: .v2)
      if type == .accounts {
        let relationships: [Relationship] =
          try await client.get(
            endpoint: Accounts.relationships(ids: newPageResults.accounts.map(\.id)))
        newPageResults.relationships = relationships
      }

      switch type {
      case .accounts:
        self.results[searchQuery]?.accounts.append(contentsOf: newPageResults.accounts)
        self.results[searchQuery]?.relationships.append(contentsOf: newPageResults.relationships)
      case .hashtags:
        self.results[searchQuery]?.hashtags.append(contentsOf: newPageResults.hashtags)
      case .statuses:
        self.results[searchQuery]?.statuses.append(contentsOf: newPageResults.statuses)
      }
    } catch {}
  }
}
