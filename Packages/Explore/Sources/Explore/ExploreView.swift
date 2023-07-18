import Account
import DesignSystem
import Env
import Models
import Network
import Shimmer
import Status
import SwiftUI

public struct ExploreView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routerPath: RouterPath

  @StateObject private var viewModel = ExploreViewModel()

  public init() {}

  public var body: some View {
    List {
      if !viewModel.isLoaded {
        quickAccessView
        loadingView
      } else if !viewModel.searchQuery.isEmpty {
        if let results = viewModel.results[viewModel.searchQuery] {
          if results.isEmpty, !viewModel.isSearching {
            EmptyView(iconName: "magnifyingglass",
                      title: "explore.search.empty.title",
                      message: "explore.search.empty.message")
              .listRowBackground(theme.secondaryBackgroundColor)
              .listRowSeparator(.hidden)
          } else {
            makeSearchResultsView(results: results)
          }
        } else {
          HStack {
            Spacer()
            ProgressView()
            Spacer()
          }
          .listRowBackground(theme.secondaryBackgroundColor)
          .listRowSeparator(.hidden)
          .id(UUID())
        }
      } else if viewModel.allSectionsEmpty {
        EmptyView(iconName: "magnifyingglass",
                  title: "explore.search.title",
                  message: "explore.search.message-\(client.server)")
          .listRowBackground(theme.secondaryBackgroundColor)
          .listRowSeparator(.hidden)
      } else {
        quickAccessView
        if !viewModel.trendingTags.isEmpty {
          trendingTagsSection
        }
        if !viewModel.suggestedAccounts.isEmpty {
          suggestedAccountsSection
        }
        if !viewModel.trendingStatuses.isEmpty {
          trendingPostsSection
        }
        if !viewModel.trendingLinks.isEmpty {
          trendingLinksSection
        }
      }
    }
    .task {
      viewModel.client = client
      await viewModel.fetchTrending()
    }
    .refreshable {
      Task {
        SoundEffectManager.shared.playSound(of: .pull)
        HapticManager.shared.fireHaptic(of: .dataRefresh(intensity: 0.3))
        await viewModel.fetchTrending()
        HapticManager.shared.fireHaptic(of: .dataRefresh(intensity: 0.7))
        SoundEffectManager.shared.playSound(of: .refresh)
      }
    }
    .listStyle(.grouped)
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
    .navigationTitle("explore.navigation-title")
    .searchable(text: $viewModel.searchQuery,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("explore.search.prompt"))
    .searchScopes($viewModel.searchScope) {
      ForEach(ExploreViewModel.SearchScope.allCases, id: \.self) { scope in
        Text(scope.localizedString)
      }
    }
  }
  
  private var quickAccessView: some View {
    ScrollView(.horizontal) {
      HStack {
        Button("explore.section.trending.tags") {
          routerPath.navigate(to: RouterDestination.tagsList(tags: viewModel.trendingTags))
        }
        .buttonStyle(.bordered)
        Button("explore.section.suggested-users") {
          routerPath.navigate(to: RouterDestination.accountsList(accounts: viewModel.suggestedAccounts))
        }
        .buttonStyle(.bordered)
        Button("explore.section.trending.posts") {
          routerPath.navigate(to: RouterDestination.trendingTimeline)
        }
        .buttonStyle(.bordered)
      }
      .padding(.horizontal, 16)
    }
    .scrollIndicators(.never)
    .listRowInsets(EdgeInsets())
    .listRowBackground(theme.secondaryBackgroundColor)
    .listRowSeparator(.hidden)
  }

  private var loadingView: some View {
    ForEach(Status.placeholders()) { status in
      StatusRowView(viewModel: { .init(status: status, client: client, routerPath: routerPath) })
        .padding(.vertical, 8)
        .redacted(reason: .placeholder)
        .listRowBackground(theme.primaryBackgroundColor)
    }
  }

  @ViewBuilder
  private func makeSearchResultsView(results: SearchResults) -> some View {
    if !results.accounts.isEmpty && (viewModel.searchScope == .all || viewModel.searchScope == .people) {
      Section("explore.section.users") {
        ForEach(results.accounts) { account in
          if let relationship = results.relationships.first(where: { $0.id == account.id }) {
            AccountsListRow(viewModel: .init(account: account, relationShip: relationship))
              .listRowBackground(theme.primaryBackgroundColor)
          }
        }
      }
    }
    if !results.hashtags.isEmpty && (viewModel.searchScope == .all || viewModel.searchScope == .hashtags) {
      Section("explore.section.tags") {
        ForEach(results.hashtags) { tag in
          TagRowView(tag: tag)
            .listRowBackground(theme.primaryBackgroundColor)
            .padding(.vertical, 4)
        }
      }
    }
    if !results.statuses.isEmpty && (viewModel.searchScope == .all || viewModel.searchScope == .posts) {
      Section("explore.section.posts") {
        ForEach(results.statuses) { status in
          StatusRowView(viewModel: { .init(status: status, client: client, routerPath: routerPath) })
            .listRowBackground(theme.primaryBackgroundColor)
            .padding(.vertical, 8)
        }
      }
    }
  }

  private var suggestedAccountsSection: some View {
    Section("explore.section.suggested-users") {
      ForEach(viewModel.suggestedAccounts
        .prefix(upTo: viewModel.suggestedAccounts.count > 3 ? 3 : viewModel.suggestedAccounts.count))
      { account in
        if let relationship = viewModel.suggestedAccountsRelationShips.first(where: { $0.id == account.id }) {
          AccountsListRow(viewModel: .init(account: account, relationShip: relationship))
            .listRowBackground(theme.primaryBackgroundColor)
        }
      }
      NavigationLink(value: RouterDestination.accountsList(accounts: viewModel.suggestedAccounts)) {
        Text("see-more")
          .foregroundColor(theme.tintColor)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }

  private var trendingTagsSection: some View {
    Section("explore.section.trending.tags") {
      ForEach(viewModel.trendingTags
        .prefix(upTo: viewModel.trendingTags.count > 5 ? 5 : viewModel.trendingTags.count))
      { tag in
        TagRowView(tag: tag)
          .listRowBackground(theme.primaryBackgroundColor)
          .padding(.vertical, 4)
      }
      NavigationLink(value: RouterDestination.tagsList(tags: viewModel.trendingTags)) {
        Text("see-more")
          .foregroundColor(theme.tintColor)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }

  private var trendingPostsSection: some View {
    Section("explore.section.trending.posts") {
      ForEach(viewModel.trendingStatuses
        .prefix(upTo: viewModel.trendingStatuses.count > 3 ? 3 : viewModel.trendingStatuses.count))
      { status in
        StatusRowView(viewModel: { .init(status: status, client: client, routerPath: routerPath) })
          .listRowBackground(theme.primaryBackgroundColor)
          .padding(.vertical, 8)
      }

      NavigationLink(value: RouterDestination.trendingTimeline) {
        Text("see-more")
          .foregroundColor(theme.tintColor)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }

  private var trendingLinksSection: some View {
    Section("explore.section.trending.links") {
      ForEach(viewModel.trendingLinks
        .prefix(upTo: viewModel.trendingLinks.count > 3 ? 3 : viewModel.trendingLinks.count))
      { card in
        StatusRowCardView(card: card)
          .listRowBackground(theme.primaryBackgroundColor)
          .padding(.vertical, 8)
      }
      NavigationLink {
        List {
          ForEach(viewModel.trendingLinks) { card in
            StatusRowCardView(card: card)
              .listRowBackground(theme.primaryBackgroundColor)
              .padding(.vertical, 8)
          }
        }
        .scrollContentBackground(.hidden)
        .background(theme.primaryBackgroundColor)
        .listStyle(.plain)
        .navigationTitle("explore.section.trending.links")
        .navigationBarTitleDisplayMode(.inline)
      } label: {
        Text("see-more")
          .foregroundColor(theme.tintColor)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }
}
