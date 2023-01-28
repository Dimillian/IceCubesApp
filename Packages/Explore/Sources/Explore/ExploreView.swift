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
        loadingView
      } else if !viewModel.searchQuery.isEmpty {
        if viewModel.isSearching {
          HStack {
            Spacer()
            ProgressView()
            Spacer()
          }
          .listRowBackground(theme.secondaryBackgroundColor)
          .listRowSeparator(.hidden)
          .id(UUID())
        } else if let results = viewModel.results[viewModel.searchQuery] {
          if results.isEmpty, !viewModel.isSearching {
            EmptyView(iconName: "magnifyingglass",
                      title: "explore.search.empty.title",
                      message: "explore.search.empty.message")
              .listRowBackground(theme.secondaryBackgroundColor)
              .listRowSeparator(.hidden)
          } else {
            makeSearchResultsView(results: results)
          }
        }
      } else if viewModel.allSectionsEmpty {
        EmptyView(iconName: "magnifyingglass",
                  title: "explore.search.title",
                  message: "explore.search.message-\(client.server)")
          .listRowBackground(theme.secondaryBackgroundColor)
          .listRowSeparator(.hidden)
      } else {
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
        await viewModel.fetchTrending()
      }
    }
    .listStyle(.grouped)
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
    .navigationTitle("explore.navigation-title")
    .searchable(text: $viewModel.searchQuery,
                prompt: Text("explore.search.prompt"))
  }

  private var loadingView: some View {
    ForEach(Status.placeholders()) { status in
      StatusRowView(viewModel: .init(status: status, isCompact: false))
        .padding(.vertical, 8)
        .redacted(reason: .placeholder)
        .shimmering()
        .listRowBackground(theme.primaryBackgroundColor)
    }
  }

  @ViewBuilder
  private func makeSearchResultsView(results: SearchResults) -> some View {
    if !results.accounts.isEmpty {
      Section("explore.section.users") {
        ForEach(results.accounts) { account in
          if let relationship = results.relationships.first(where: { $0.id == account.id }) {
            AccountsListRow(viewModel: .init(account: account, relationShip: relationship))
              .listRowBackground(theme.primaryBackgroundColor)
          }
        }
      }
    }
    if !results.hashtags.isEmpty {
      Section("explore.section.tags") {
        ForEach(results.hashtags) { tag in
          TagRowView(tag: tag)
            .listRowBackground(theme.primaryBackgroundColor)
            .padding(.vertical, 4)
        }
      }
    }
    if !results.statuses.isEmpty {
      Section("explore.section.posts") {
        ForEach(results.statuses) { status in
          StatusRowView(viewModel: .init(status: status))
            .listRowBackground(theme.primaryBackgroundColor)
            .padding(.vertical, 8)
        }
      }
    }
  }

  private var suggestedAccountsSection: some View {
    Section("explore.section.suggested-users") {
      ForEach(viewModel.suggestedAccounts
        .prefix(upTo: viewModel.suggestedAccounts.count > 3 ? 3 : viewModel.suggestedAccounts.count)) { account in
          if let relationship = viewModel.suggestedAccountsRelationShips.first(where: { $0.id == account.id }) {
            AccountsListRow(viewModel: .init(account: account, relationShip: relationship))
              .listRowBackground(theme.primaryBackgroundColor)
          }
        }
      NavigationLink {
        List {
          ForEach(viewModel.suggestedAccounts) { account in
            if let relationship = viewModel.suggestedAccountsRelationShips.first(where: { $0.id == account.id }) {
              AccountsListRow(viewModel: .init(account: account, relationShip: relationship))
                .listRowBackground(theme.primaryBackgroundColor)
            }
          }
        }
        .scrollContentBackground(.hidden)
        .background(theme.primaryBackgroundColor)
        .listStyle(.plain)
        .navigationTitle("explore.section.suggested-users")
        .navigationBarTitleDisplayMode(.inline)
      } label: {
        Text("see-more")
          .foregroundColor(theme.tintColor)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }

  private var trendingTagsSection: some View {
    Section("explore.section.trending.tags") {
      ForEach(viewModel.trendingTags
        .prefix(upTo: viewModel.trendingTags.count > 5 ? 5 : viewModel.trendingTags.count)) { tag in
          TagRowView(tag: tag)
            .listRowBackground(theme.primaryBackgroundColor)
            .padding(.vertical, 4)
        }
      NavigationLink {
        List {
          ForEach(viewModel.trendingTags) { tag in
            TagRowView(tag: tag)
              .listRowBackground(theme.primaryBackgroundColor)
              .padding(.vertical, 4)
          }
        }
        .scrollContentBackground(.hidden)
        .background(theme.primaryBackgroundColor)
        .listStyle(.plain)
        .navigationTitle("explore.section.trending.tags")
        .navigationBarTitleDisplayMode(.inline)
      } label: {
        Text("see-more")
          .foregroundColor(theme.tintColor)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }

  private var trendingPostsSection: some View {
    Section("explore.section.trending.posts") {
      ForEach(viewModel.trendingStatuses
        .prefix(upTo: viewModel.trendingStatuses.count > 3 ? 3 : viewModel.trendingStatuses.count)) { status in
          StatusRowView(viewModel: .init(status: status, isCompact: false))
            .listRowBackground(theme.primaryBackgroundColor)
            .padding(.vertical, 8)
        }

      NavigationLink {
        List {
          ForEach(viewModel.trendingStatuses) { status in
            StatusRowView(viewModel: .init(status: status, isCompact: false))
              .listRowBackground(theme.primaryBackgroundColor)
              .padding(.vertical, 8)
          }
        }
        .scrollContentBackground(.hidden)
        .background(theme.primaryBackgroundColor)
        .listStyle(.plain)
        .navigationTitle("explore.section.trending.posts")
        .navigationBarTitleDisplayMode(.inline)
      } label: {
        Text("see-more")
          .foregroundColor(theme.tintColor)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }

  private var trendingLinksSection: some View {
    Section("explore.section.trending.links") {
      ForEach(viewModel.trendingLinks
        .prefix(upTo: viewModel.trendingLinks.count > 3 ? 3 : viewModel.trendingLinks.count)) { card in
          StatusCardView(card: card)
            .listRowBackground(theme.primaryBackgroundColor)
            .padding(.vertical, 8)
        }
      NavigationLink {
        List {
          ForEach(viewModel.trendingLinks) { card in
            StatusCardView(card: card)
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
