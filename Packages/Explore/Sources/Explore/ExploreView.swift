import Account
import DesignSystem
import Env
import Models
import Network
import StatusKit
import SwiftUI

@MainActor
public struct ExploreView: View {
  @Environment(Theme.self) private var theme
  @Environment(Client.self) private var client
  @Environment(RouterPath.self) private var routerPath

  @State private var viewModel = ExploreViewModel()

  @Binding var scrollToTopSignal: Int

  public init(scrollToTopSignal: Binding<Int>) {
    _scrollToTopSignal = scrollToTopSignal
  }

  public var body: some View {
    ScrollViewReader { proxy in
      List {
        scrollToTopView
          .padding(.bottom, 4)
        if !viewModel.isLoaded {
          quickAccessView
            .padding(.bottom, 5)
          loadingView
        } else if !viewModel.searchQuery.isEmpty {
          if let results = viewModel.results[viewModel.searchQuery] {
            if results.isEmpty, !viewModel.isSearching {
              PlaceholderView(iconName: "magnifyingglass",
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
            #if !os(visionOS)
            .listRowBackground(theme.secondaryBackgroundColor)
            #endif
            .listRowSeparator(.hidden)
            .id(UUID())
          }
        } else if viewModel.allSectionsEmpty {
          PlaceholderView(iconName: "magnifyingglass",
                          title: "explore.search.title",
                          message: "explore.search.message-\(client.server)")
          #if !os(visionOS)
            .listRowBackground(theme.secondaryBackgroundColor)
          #endif
            .listRowSeparator(.hidden)
        } else {
          quickAccessView
            .padding(.bottom, 4)

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
      .environment(\.defaultMinListRowHeight, .scrollToViewHeight)
      .task {
        viewModel.client = client
        await viewModel.fetchTrending()
      }
      .refreshable {
        Task {
          SoundEffectManager.shared.playSound(.pull)
          HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.3))
          await viewModel.fetchTrending()
          HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.7))
          SoundEffectManager.shared.playSound(.refresh)
        }
      }
      .listStyle(.plain)
      #if !os(visionOS)
        .scrollContentBackground(.hidden)
        .background(theme.secondaryBackgroundColor)
      #endif
        .navigationTitle("explore.navigation-title")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchQuery,
                    isPresented: $viewModel.isSearchPresented,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text("explore.search.prompt"))
        .searchScopes($viewModel.searchScope) {
          ForEach(ExploreViewModel.SearchScope.allCases, id: \.self) { scope in
            Text(scope.localizedString)
          }
        }
        .task(id: viewModel.searchQuery) {
          await viewModel.search()
        }
        .onChange(of: scrollToTopSignal) {
          if viewModel.scrollToTopVisible {
            viewModel.isSearchPresented.toggle()
          } else {
            withAnimation {
              proxy.scrollTo(ScrollToView.Constants.scrollToTop, anchor: .top)
            }
          }
        }
    }
  }

  private var quickAccessView: some View {
    ScrollView(.horizontal) {
      HStack {
        Button("explore.section.trending.links") {
          routerPath.navigate(to: RouterDestination.trendingLinks(cards: viewModel.trendingLinks))
        }
        .buttonStyle(.bordered)
        Button("explore.section.trending.posts") {
          routerPath.navigate(to: RouterDestination.trendingTimeline)
        }
        .buttonStyle(.bordered)
        Button("explore.section.suggested-users") {
          routerPath.navigate(to: RouterDestination.accountsList(accounts: viewModel.suggestedAccounts))
        }
        .buttonStyle(.bordered)
        Button("explore.section.trending.tags") {
          routerPath.navigate(to: RouterDestination.tagsList(tags: viewModel.trendingTags))
        }
        .buttonStyle(.bordered)
      }
      .padding(.horizontal, 16)
    }
    .scrollIndicators(.never)
    .listRowInsets(EdgeInsets())
    #if !os(visionOS)
      .listRowBackground(theme.secondaryBackgroundColor)
    #endif
      .listRowSeparator(.hidden)
  }

  private var loadingView: some View {
    ForEach(Status.placeholders()) { status in
      StatusRowView(viewModel: .init(status: status, client: client, routerPath: routerPath))
        .padding(.vertical, 8)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
  }

  @ViewBuilder
  private func makeSearchResultsView(results: SearchResults) -> some View {
    if !results.accounts.isEmpty, viewModel.searchScope == .all || viewModel.searchScope == .people {
      Section("explore.section.users") {
        ForEach(results.accounts) { account in
          if let relationship = results.relationships.first(where: { $0.id == account.id }) {
            AccountsListRow(viewModel: .init(account: account, relationShip: relationship))
            #if !os(visionOS)
              .listRowBackground(theme.primaryBackgroundColor)
            #else
              .listRowBackground(RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(.background).hoverEffect())
              .listRowHoverEffectDisabled()
            #endif
          }
        }
      }
    }
    if !results.hashtags.isEmpty, viewModel.searchScope == .all || viewModel.searchScope == .hashtags {
      Section("explore.section.tags") {
        ForEach(results.hashtags) { tag in
          TagRowView(tag: tag)
          #if !os(visionOS)
            .listRowBackground(theme.primaryBackgroundColor)
          #else
            .listRowBackground(RoundedRectangle(cornerRadius: 8)
              .foregroundStyle(.background).hoverEffect())
            .listRowHoverEffectDisabled()
          #endif
            .padding(.vertical, 4)
        }
      }
    }
    if !results.statuses.isEmpty, viewModel.searchScope == .all || viewModel.searchScope == .posts {
      Section("explore.section.posts") {
        ForEach(results.statuses) { status in
          StatusRowView(viewModel: .init(status: status, client: client, routerPath: routerPath))
          #if !os(visionOS)
            .listRowBackground(theme.primaryBackgroundColor)
          #else
            .listRowBackground(RoundedRectangle(cornerRadius: 8)
              .foregroundStyle(.background).hoverEffect())
            .listRowHoverEffectDisabled()
          #endif
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
          #if !os(visionOS)
            .listRowBackground(theme.primaryBackgroundColor)
          #else
            .listRowBackground(RoundedRectangle(cornerRadius: 8)
              .foregroundStyle(.background).hoverEffect())
            .listRowHoverEffectDisabled()
          #endif
        }
      }
      NavigationLink(value: RouterDestination.accountsList(accounts: viewModel.suggestedAccounts)) {
        Text("see-more")
          .foregroundColor(theme.tintColor)
      }
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
      #else
      .listRowBackground(RoundedRectangle(cornerRadius: 8)
        .foregroundStyle(.background).hoverEffect())
      .listRowHoverEffectDisabled()
      #endif
    }
  }

  private var trendingTagsSection: some View {
    Section("explore.section.trending.tags") {
      ForEach(viewModel.trendingTags
        .prefix(upTo: viewModel.trendingTags.count > 5 ? 5 : viewModel.trendingTags.count))
      { tag in
        TagRowView(tag: tag)
        #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor)
        #else
          .listRowBackground(RoundedRectangle(cornerRadius: 8)
            .foregroundStyle(.background).hoverEffect())
          .listRowHoverEffectDisabled()
        #endif
          .padding(.vertical, 4)
      }
      NavigationLink(value: RouterDestination.tagsList(tags: viewModel.trendingTags)) {
        Text("see-more")
          .foregroundColor(theme.tintColor)
      }
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
      #else
      .listRowBackground(RoundedRectangle(cornerRadius: 8)
        .foregroundStyle(.background).hoverEffect())
      .listRowHoverEffectDisabled()
      #endif
    }
  }

  private var trendingPostsSection: some View {
    Section("explore.section.trending.posts") {
      ForEach(viewModel.trendingStatuses
        .prefix(upTo: viewModel.trendingStatuses.count > 3 ? 3 : viewModel.trendingStatuses.count))
      { status in
        StatusRowView(viewModel: .init(status: status, client: client, routerPath: routerPath))
        #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor)
        #else
          .listRowBackground(RoundedRectangle(cornerRadius: 8)
            .foregroundStyle(.background).hoverEffect())
          .listRowHoverEffectDisabled()
        #endif
          .padding(.vertical, 8)
      }

      NavigationLink(value: RouterDestination.trendingTimeline) {
        Text("see-more")
          .foregroundColor(theme.tintColor)
      }
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
      #else
      .listRowBackground(RoundedRectangle(cornerRadius: 8)
        .foregroundStyle(.background).hoverEffect())
      .listRowHoverEffectDisabled()
      #endif
    }
  }

  private var trendingLinksSection: some View {
    Section("explore.section.trending.links") {
      ForEach(viewModel.trendingLinks
        .prefix(upTo: viewModel.trendingLinks.count > 3 ? 3 : viewModel.trendingLinks.count))
      { card in
        StatusRowCardView(card: card)
          .environment(\.isCompact, true)
        #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor)
        #else
          .listRowBackground(RoundedRectangle(cornerRadius: 8)
            .foregroundStyle(.background).hoverEffect())
          .listRowHoverEffectDisabled()
        #endif
          .padding(.vertical, 8)
      }

      NavigationLink(value: RouterDestination.trendingLinks(cards: viewModel.trendingLinks)) {
        Text("see-more")
          .foregroundColor(theme.tintColor)
      }
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
      #else
      .listRowBackground(RoundedRectangle(cornerRadius: 8)
        .foregroundStyle(.background).hoverEffect())
      .listRowHoverEffectDisabled()
      #endif
    }
  }

  private var scrollToTopView: some View {
    ScrollToView()
      .frame(height: .scrollToViewHeight)
      .onAppear {
        viewModel.scrollToTopVisible = true
      }
      .onDisappear {
        viewModel.scrollToTopVisible = false
      }
  }
}
