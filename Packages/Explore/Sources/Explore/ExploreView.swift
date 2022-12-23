import SwiftUI
import Env
import Network
import DesignSystem
import Models
import Status
import Shimmer
import Account

public struct ExploreView: View {
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routeurPath: RouterPath
  
  @StateObject private var viewModel = ExploreViewModel()
  @State private var searchQuery: String = ""
      
  public init() { }
  
  public var body: some View {
    List {
      if !viewModel.isLoaded {
        ForEach(Status.placeholders()) { status in
          StatusRowView(viewModel: .init(status: status, isEmbed: false))
            .padding(.vertical, 8)
            .redacted(reason: .placeholder)
            .shimmering()
        }
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
    .navigationTitle("Explore")
    .searchable(text: $searchQuery)
  }
  
  private var suggestedAccountsSection: some View {
    Section("Suggested Users") {
      ForEach(viewModel.suggestedAccounts
        .prefix(upTo: viewModel.suggestedAccounts.count > 3 ? 3 : viewModel.suggestedAccounts.count)) { account in
        if let relationship = viewModel.suggestedAccountsRelationShips.first(where: { $0.id == account.id }) {
          AccountsListRow(viewModel: .init(account: account, relationShip: relationship))
        }
      }
      NavigationLink {
        List {
          ForEach(viewModel.suggestedAccounts) { account in
            if let relationship = viewModel.suggestedAccountsRelationShips.first(where: { $0.id == account.id }) {
              AccountsListRow(viewModel: .init(account: account, relationShip: relationship))
            }
          }
        }
        .listStyle(.plain)
        .navigationTitle("Suggested Users")
        .navigationBarTitleDisplayMode(.inline)
      } label: {
        Text("See more")
          .foregroundColor(.brand)
      }
    }
  }
  
  private var trendingTagsSection: some View {
    Section("Trending Tags") {
      ForEach(viewModel.trendingTags
        .prefix(upTo: viewModel.trendingTags.count > 5 ? 5 : viewModel.trendingTags.count)) { tag in
        TagRowView(tag: tag)
          .padding(.vertical, 4)
      }
      NavigationLink {
        List {
          ForEach(viewModel.trendingTags) { tag in
            TagRowView(tag: tag)
              .padding(.vertical, 4)
          }
        }
        .listStyle(.plain)
        .navigationTitle("Trending Tags")
        .navigationBarTitleDisplayMode(.inline)
      } label: {
        Text("See more")
          .foregroundColor(.brand)
      }
    }
  }
  
  private var trendingPostsSection: some View {
    Section("Trending Posts") {
      ForEach(viewModel.trendingStatuses
        .prefix(upTo: viewModel.trendingStatuses.count > 3 ? 3 : viewModel.trendingStatuses.count)) { status in
        StatusRowView(viewModel: .init(status: status, isEmbed: false))
          .padding(.vertical, 8)
      }
      
      NavigationLink {
        List {
          ForEach(viewModel.trendingStatuses) { status in
            StatusRowView(viewModel: .init(status: status, isEmbed: false))
              .padding(.vertical, 8)
          }
        }
        .listStyle(.plain)
        .navigationTitle("Trending Posts")
        .navigationBarTitleDisplayMode(.inline)
      } label: {
        Text("See more")
          .foregroundColor(.brand)
      }
    }
  }
  
  private var trendingLinksSection: some View {
    Section("Trending Links") {
      ForEach(viewModel.trendingLinks
        .prefix(upTo: viewModel.trendingLinks.count > 3 ? 3 : viewModel.trendingLinks.count)) { card in
        StatusCardView(card: card)
          .padding(.vertical, 8)
      }
      NavigationLink {
        List {
          ForEach(viewModel.trendingLinks) { card in
            StatusCardView(card: card)
              .padding(.vertical, 8)
          }
        }
        .listStyle(.plain)
        .navigationTitle("Trending Links")
        .navigationBarTitleDisplayMode(.inline)
      } label: {
        Text("See more")
          .foregroundColor(.brand)
      }
    }
  }
  
}
