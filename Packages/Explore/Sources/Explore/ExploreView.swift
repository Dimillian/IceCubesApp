import SwiftUI
import Env
import Network
import DesignSystem
import Models
import Status
import Shimmer
import Account

public struct ExploreView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routeurPath: RouterPath
  
  @StateObject private var viewModel = ExploreViewModel()
        
  public init() { }
  
  public var body: some View {
    List {
      if !viewModel.searchQuery.isEmpty {
        if let results = viewModel.results[viewModel.searchQuery] {
          makeSearchResultsView(results: results)
        } else {
          loadingView
        }
      } else if !viewModel.isLoaded {
        loadingView
      } else {
        trendingTagsSection
        suggestedAccountsSection
        trendingPostsSection
        trendingLinksSection
      }
    }
    .task {
      viewModel.client = client
      guard !viewModel.isLoaded else { return }
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
    .navigationTitle("Explore")
    .searchable(text: $viewModel.searchQuery,
                tokens: $viewModel.tokens,
                suggestedTokens: $viewModel.suggestedToken,
                prompt: Text("Search users, posts and tags"),
                token: { token in
      Text(token.rawValue)
    })
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
      Section("Users") {
        ForEach(results.accounts) { account in
          if let relationship = results.relationships.first(where: { $0.id == account.id }) {
            AccountsListRow(viewModel: .init(account: account, relationShip: relationship))
              .listRowBackground(theme.primaryBackgroundColor)
          }
        }
      }
    }
    if !results.hashtags.isEmpty {
      Section("Tags") {
        ForEach(results.hashtags) { tag in
          TagRowView(tag: tag)
            .listRowBackground(theme.primaryBackgroundColor)
            .padding(.vertical, 4)
        }
      }
    }
    if !results.statuses.isEmpty {
      Section("Posts") {
        ForEach(results.statuses) { status in
          StatusRowView(viewModel: .init(status: status))
            .listRowBackground(theme.primaryBackgroundColor)
            .padding(.vertical, 8)
        }
      }
    }
  }
  
  private var suggestedAccountsSection: some View {
    Section("Suggested Users") {
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
        .navigationTitle("Suggested Users")
        .navigationBarTitleDisplayMode(.inline)
      } label: {
        Text("See more")
          .foregroundColor(theme.tintColor)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }
  
  private var trendingTagsSection: some View {
    Section("Trending Tags") {
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
        .navigationTitle("Trending Tags")
        .navigationBarTitleDisplayMode(.inline)
      } label: {
        Text("See more")
          .foregroundColor(theme.tintColor)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }
  
  private var trendingPostsSection: some View {
    Section("Trending Posts") {
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
        .navigationTitle("Trending Posts")
        .navigationBarTitleDisplayMode(.inline)
      } label: {
        Text("See more")
          .foregroundColor(theme.tintColor)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }
  
  private var trendingLinksSection: some View {
    Section("Trending Links") {
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
        .navigationTitle("Trending Links")
        .navigationBarTitleDisplayMode(.inline)
      } label: {
        Text("See more")
          .foregroundColor(theme.tintColor)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }
  
}
