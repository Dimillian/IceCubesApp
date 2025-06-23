import DesignSystem
import EmojiText
import Env
import Models
import Network
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
  @Environment(Client.self) private var client
  @Environment(RouterPath.self) private var routerPath

  private let accountId: String
  private let initialAccount: Account?
  
  @State private var viewState: AccountDetailState = .loading
  @State private var account: Account?
  @State private var relationship: Relationship?
  @State private var featuredTags: [FeaturedTag] = []
  @State private var familiarFollowers: [Account] = []
  @State private var fields: [Account.Field] = []
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
    self.initialAccount = nil
  }

  /// When the account is already fetched by the parent caller.
  public init(account: Account) {
    self.accountId = account.id
    self.initialAccount = account
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
        familiarFollowersView
          .applyAccountDetailsRowStyle(theme: theme)
        featuredTagsView
          .applyAccountDetailsRowStyle(theme: theme)

        if let tabManager {
          makeTabPicker(tabManager: tabManager)
            .pickerStyle(.segmented)
            .padding(.layoutPadding)
            .applyAccountDetailsRowStyle(theme: theme)
            .id("status")

          let fetcher = tabManager.getFetcher(for: tabManager.selectedTab)
          tabManager.selectedTab.makeView(
            fetcher: fetcher,
            client: client,
            routerPath: routerPath,
            account: account
          )
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
      
      if let initialAccount {
        account = initialAccount
        viewState = .display(account: initialAccount, featuredTags: [], relationships: [])
      }

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
      toolbarContent
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
        if tab.id == "boosts" {
          Image("Rocket")
            .tag(tab.id as String?)
            .accessibilityLabel(tab.accessibilityLabel)
        } else {
          Image(systemName: tab.iconName)
            .tag(tab.id as String?)
            .accessibilityLabel(tab.accessibilityLabel)
        }
      }
    }
  }

  @ViewBuilder
  private func makeHeaderView(proxy: ScrollViewProxy?) -> some View {
    switch viewState {
    case .loading:
      AccountDetailHeaderView(
        account: .placeholder(),
        relationship: $relationship,
        fields: $fields,
        familiarFollowers: $familiarFollowers,
        followButtonViewModel: $followButtonViewModel,
        translation: $translation,
        isLoadingTranslation: $isLoadingTranslation,
        isCurrentUser: isCurrentUser,
        accountId: accountId,
        scrollViewProxy: proxy
      )
      .redacted(reason: .placeholder)
      .allowsHitTesting(false)
    case .display(let account, _, _):
      AccountDetailHeaderView(
        account: account,
        relationship: $relationship,
        fields: $fields,
        familiarFollowers: $familiarFollowers,
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

  @ViewBuilder
  private var featuredTagsView: some View {
    if !featuredTags.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 4) {
          if !featuredTags.isEmpty {
            ForEach(featuredTags) { tag in
              Button {
                routerPath.navigate(to: .hashTag(tag: tag.name, account: accountId))
              } label: {
                VStack(alignment: .leading, spacing: 0) {
                  Text("#\(tag.name)")
                    .font(.scaledCallout)
                  Text("account.detail.featured-tags-n-posts \(tag.statusesCountInt)")
                    .font(.caption2)
                }
              }.buttonStyle(.bordered)
            }
          }
        }
        .padding(.leading, .layoutPadding)
      }
    }
  }

  @ViewBuilder
  private var familiarFollowersView: some View {
    if !familiarFollowers.isEmpty {
      VStack(alignment: .leading, spacing: 2) {
        Text("account.detail.familiar-followers")
          .font(.scaledHeadline)
          .padding(.leading, .layoutPadding)
          .accessibilityAddTraits(.isHeader)
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(spacing: 0) {
            ForEach(familiarFollowers) { account in
              Button {
                routerPath.navigate(to: .accountDetailWithAccount(account: account))
              } label: {
                AvatarView(account.avatar, config: .badge)
                  .padding(.leading, -4)
                  .accessibilityLabel(account.safeDisplayName)
              }
              .accessibilityAddTraits(.isImage)
              .buttonStyle(.plain)
            }
          }
          .padding(.leading, .layoutPadding + 4)
        }
      }
      .padding(.top, 2)
      .padding(.bottom, 12)
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      if let account = account, displayTitle {
        VStack {
          Text(account.displayName ?? "").font(.headline)
          Text("account.detail.featured-tags-n-posts \(account.statusesCount ?? 0)")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
      }
    }
    ToolbarItemGroup(placement: .navigationBarTrailing) {
      if !isCurrentUser {
        Button {
          if let account = account {
            #if targetEnvironment(macCatalyst) || os(visionOS)
              openWindow(
                value: WindowDestinationEditor.mentionStatusEditor(
                  account: account, visibility: preferences.postVisibility))
            #else
              routerPath.presentedSheet = .mentionStatusEditor(
                account: account,
                visibility: preferences.postVisibility)
            #endif
          }
        } label: {
          Image(systemName: "arrowshape.turn.up.left")
        }
      }

      Menu {
        AccountDetailContextMenu(
          showBlockConfirmation: $showBlockConfirmation,
          showTranslateView: $showTranslateView,
          account: account,
          relationship: $relationship,
          isCurrentUser: isCurrentUser)

        if !isCurrentUser {
          Button {
            isEditingRelationshipNote = true
          } label: {
            Label("account.relation.note.edit", systemImage: "pencil")
          }
        }

        if isCurrentUser {
          Button {
            routerPath.presentedSheet = .accountEditInfo
          } label: {
            Label("account.action.edit-info", systemImage: "pencil")
          }

          Button {
            if let url = URL(string: "https://\(client.server)/settings/privacy") {
              openURL(url)
            }
          } label: {
            Label("account.action.privacy-settings", systemImage: "lock")
          }

          if currentInstance.isFiltersSupported {
            Button {
              routerPath.presentedSheet = .accountFiltersList
            } label: {
              Label("account.action.edit-filters", systemImage: "line.3.horizontal.decrease.circle")
            }
          }

          Button {
            routerPath.presentedSheet = .accountPushNotficationsSettings
          } label: {
            Label("settings.push.navigation-title", systemImage: "bell")
          }

          if let account = account {
            Divider()

            Button {
              routerPath.navigate(to: .blockedAccounts)
            } label: {
              Label("account.blocked", systemImage: "person.crop.circle.badge.xmark")
            }

            Button {
              routerPath.navigate(to: .mutedAccounts)
            } label: {
              Label("account.muted", systemImage: "person.crop.circle.badge.moon")
            }

            Divider()

            Button {
              if let url = URL(
                string:
                  "https://mastometrics.com/auth/login?username=\(account.acct)@\(client.server)&instance=\(client.server)&auto=true"
              ) {
                openURL(url)
              }
            } label: {
              Label("Mastometrics", systemImage: "chart.xyaxis.line")
            }

            Divider()
          }

          Button {
            routerPath.presentedSheet = .settings
          } label: {
            Label("settings.title", systemImage: "gear")
          }
        }
      } label: {
        Image(systemName: "ellipsis")
          .accessibilityLabel("accessibility.tabs.profile.options.label")
          .accessibilityInputLabels([
            LocalizedStringKey("accessibility.tabs.profile.options.label"),
            LocalizedStringKey("accessibility.tabs.profile.options.inputLabel1"),
            LocalizedStringKey("accessibility.tabs.profile.options.inputLabel2"),
          ])
          .foregroundStyle(theme.tintColor)
      }
      .confirmationDialog("Block User", isPresented: $showBlockConfirmation) {
        if let account = account {
          Button("account.action.block-user-\(account.username)", role: .destructive) {
            Task {
              do {
                relationship = try await client.post(
                  endpoint: Accounts.block(id: account.id))
              } catch {}
            }
          }
        }
      } message: {
        Text("account.action.block-user-confirmation")
      }
      .tint(.label)
      #if canImport(_Translation_SwiftUI)
        .addTranslateView(
          isPresented: $showTranslateView, text: account?.note.asRawText ?? "")
      #endif
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
      
      viewState = .display(account: data.account, featuredTags: data.featuredTags, relationships: data.relationships)
      account = data.account
      fields = data.account.fields
      featuredTags = data.featuredTags
      featuredTags.sort { $0.statusesCountInt > $1.statusesCountInt }
      relationship = data.relationships.first
      
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
      if let account {
        viewState = .display(account: account, featuredTags: [], relationships: [])
      } else {
        viewState = .error(error: error)
      }
    }
  }
  
  private func fetchAccountData(accountId: String, client: Client) async throws -> AccountData {
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
