import DesignSystem
import EmojiText
import Env
import Models
import NetworkClient
import StatusKit
import SwiftUI

@MainActor
public struct AccountDetailView: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.redactionReasons) private var reasons
  @Environment(\.openWindow) private var openWindow

  @Environment(StreamWatcher.self) private var watcher
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(UserPreferences.self) private var preferences
  @Environment(Theme.self) private var theme
  @Environment(MastodonClient.self) private var client
  @Environment(RouterPath.self) private var routerPath

  private let accountId: String

  @State private var viewState: AccountDetailState = .loading
  @State private var relationship: Relationship?
  @State private var familiarFollowers: [Account] = []
  @State private var followButtonViewModel: FollowButtonViewModel?
  @State private var translation: Translation?
  @State private var isLoadingTranslation = false
  @State private var isCurrentUser: Bool = false

  @State private var showBlockConfirmation: Bool = false
  @State private var isEditingRelationshipNote: Bool = false
  @State private var showTranslateView: Bool = false
  @State private var tabManager: AccountTabManager?

  @State private var displayTitle: Bool = false

  /// When coming from a URL like a mention tap in a status.
  public init(accountId: String) {
    self.accountId = accountId
    _viewState = .init(initialValue: .loading)
  }

  /// When the account is already fetched by the parent caller.
  public init(account: Account) {
    self.accountId = account.id
    _viewState = .init(
      initialValue: .display(account: account, featuredTags: [], relationships: [], fields: []))
  }

  public var body: some View {
    ScrollViewReader { proxy in
      List {
        ScrollToView()
          .onAppear { displayTitle = false }
          .onDisappear { displayTitle = true }
        makeHeaderView(proxy: proxy)
          .applyAccountDetailsRowStyle(theme: theme)
          .padding(.bottom, -20)

        switch viewState {
        case .display(let account, let featuredTags, _, _):
          FamiliarFollowersView(familiarFollowers: familiarFollowers)
            .applyAccountDetailsRowStyle(theme: theme)
          FeaturedTagsView(featuredTags: featuredTags, accountId: accountId)
            .applyAccountDetailsRowStyle(theme: theme)
          if let tabManager {
            makeTabPicker(tabManager: tabManager)
              .pickerStyle(.segmented)
              .padding(.layoutPadding)
              .applyAccountDetailsRowStyle(theme: theme)
              .id("status")

            AnyView(
              tabManager.selectedTab.makeView(
                fetcher: tabManager.getFetcher(for: tabManager.selectedTab),
                client: client,
                routerPath: routerPath,
                account: account
              ))
          }
        default:
          EmptyView()
        }
      }
      .environment(\.defaultMinListRowHeight, 0)
      .listStyle(.plain)
      #if !os(visionOS)
        .scrollContentBackground(.hidden)
        .background(theme.primaryBackgroundColor)
      #endif
    }
    .onAppear {
      guard reasons != .placeholder else { return }
      isCurrentUser = currentAccount.account?.id == accountId

      if tabManager == nil {
        tabManager = AccountTabManager(
          accountId: accountId,
          client: client,
          isCurrentUser: isCurrentUser
        )
      }

      if let tabManager {
        Task {
          await withTaskGroup(of: Void.self) { group in
            group.addTask {
              await fetchAccount()
            }
            switch tabManager.currentTabFetcher.statusesState {
            case .loading, .error:
              group.addTask {
                await tabManager.currentTabFetcher.fetchNewestStatuses(pullToRefresh: false)
              }
            default:
              break
            }
            if !isCurrentUser {
              group.addTask {
                await fetchFamiliarFollowers()
              }
            }
          }
        }
      }
    }
    .refreshable {
      Task {
        SoundEffectManager.shared.playSound(.pull)
        HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.3))
        await fetchAccount()
        if let tabManager {
          await tabManager.refreshCurrentTab()
        }
        HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.7))
        SoundEffectManager.shared.playSound(.refresh)
      }
    }
    .onChange(of: watcher.latestEvent?.id) {
      if let latestEvent = watcher.latestEvent,
        accountId == currentAccount.account?.id,
        let tabManager
      {
        // Handle stream events directly with the current tab's fetcher
        if let fetcher = tabManager.currentTabFetcher as? AccountTabFetcher {
          fetcher.handleEvent(event: latestEvent, currentAccount: currentAccount)
        }
      }
    }
    .onChange(of: routerPath.presentedSheet) { oldValue, newValue in
      if oldValue == .accountEditInfo || newValue == .accountEditInfo {
        Task {
          await fetchAccount()
          await preferences.refreshServerPreferences()
        }
      }
    }
    .sheet(
      isPresented: $isEditingRelationshipNote,
      content: {
        EditRelationshipNoteView(
          accountId: accountId,
          relationship: relationship,
          onSave: {
            Task {
              await fetchAccount()
            }
          }
        )
      }
    )
    .edgesIgnoringSafeArea(.top)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      switch viewState {
      case .display(let account, _, _, _):
        AccountDetailToolbar(
          account: account,
          displayTitle: displayTitle,
          isCurrentUser: isCurrentUser,
          relationship: $relationship,
          showBlockConfirmation: $showBlockConfirmation,
          showTranslateView: $showTranslateView,
          isEditingRelationshipNote: $isEditingRelationshipNote
        )
      default:
        ToolbarItem {
          EmptyView()
        }
      }
    }
  }

  @ViewBuilder
  private func makeTabPicker(tabManager: AccountTabManager) -> some View {
    Picker(
      "",
      selection: .init(
        get: { tabManager.selectedTabId },
        set: { newTabId in
          if let newTab = tabManager.availableTabs.first(where: { $0.id == newTabId }) {
            tabManager.selectedTab = newTab
          }
        })
    ) {
      ForEach(tabManager.availableTabs, id: \.id) { tab in
        Image(systemName: tab.iconName)
          .tag(tab.id as String?)
          .accessibilityLabel(tab.accessibilityLabel)
      }
    }
  }

  @ViewBuilder
  private func makeHeaderView(proxy: ScrollViewProxy?) -> some View {
    switch viewState {
    case .loading:
      AccountDetailHeaderView(
        account: .placeholder(),
        relationship: relationship,
        fields: [],
        followButtonViewModel: $followButtonViewModel,
        translation: $translation,
        isLoadingTranslation: $isLoadingTranslation,
        isCurrentUser: isCurrentUser,
        accountId: accountId,
        scrollViewProxy: proxy
      )
      .redacted(reason: .placeholder)
      .allowsHitTesting(false)
    case .display(let account, _, _, let fields):
      AccountDetailHeaderView(
        account: account,
        relationship: relationship,
        fields: fields,
        followButtonViewModel: $followButtonViewModel,
        translation: $translation,
        isLoadingTranslation: $isLoadingTranslation,
        isCurrentUser: isCurrentUser,
        accountId: accountId,
        scrollViewProxy: proxy)
    case .error(let error):
      Text("Error: \(error.localizedDescription)")
    }
  }

}

extension View {
  @MainActor
  func applyAccountDetailsRowStyle(theme: Theme) -> some View {
    listRowInsets(.init())
      .listRowSeparator(.hidden)
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif
  }
}

struct AccountDetailView_Previews: PreviewProvider {
  static var previews: some View {
    AccountDetailView(account: .placeholder())
  }
}

// MARK: - Data Fetching
extension AccountDetailView {
  private struct AccountData {
    let account: Account
    let featuredTags: [FeaturedTag]
    let relationships: [Relationship]
  }

  private func fetchAccount() async {
    do {
      let data = try await fetchAccountData(accountId: accountId, client: client)

      var featuredTags = data.featuredTags
      featuredTags.sort { $0.statusesCountInt > $1.statusesCountInt }
      relationship = data.relationships.first

      viewState = .display(
        account: data.account,
        featuredTags: featuredTags,
        relationships: data.relationships,
        fields: data.account.fields)

      if let relationship {
        if let existingFollowButtonViewModel = followButtonViewModel {
          existingFollowButtonViewModel.relationship = relationship
        } else {
          followButtonViewModel = .init(
            client: client,
            accountId: accountId,
            relationship: relationship,
            shouldDisplayNotify: true,
            relationshipUpdated: { relationship in
              self.relationship = relationship
            })
        }
      }
    } catch {
      if case .display(let account, _, _, _) = viewState {
        viewState = .display(account: account, featuredTags: [], relationships: [], fields: [])
      } else {
        viewState = .error(error: error)
      }
    }
  }

  private func fetchAccountData(accountId: String, client: MastodonClient) async throws
    -> AccountData
  {
    async let account: Account = client.get(endpoint: Accounts.accounts(id: accountId))
    async let featuredTags: [FeaturedTag] = client.get(
      endpoint: Accounts.featuredTags(id: accountId))
    if client.isAuth, !isCurrentUser {
      async let relationships: [Relationship] = client.get(
        endpoint: Accounts.relationships(ids: [accountId]))
      do {
        return try await .init(
          account: account,
          featuredTags: featuredTags,
          relationships: relationships)
      } catch {
        return try await .init(
          account: account,
          featuredTags: [],
          relationships: relationships)
      }
    }
    return try await .init(
      account: account,
      featuredTags: featuredTags,
      relationships: [])
  }

  private func fetchFamiliarFollowers() async {
    let familiarFollowersResponse: [FamiliarAccounts]? = try? await client.get(
      endpoint: Accounts.familiarFollowers(withAccount: accountId))
    self.familiarFollowers = familiarFollowersResponse?.first?.accounts ?? []
  }
}
