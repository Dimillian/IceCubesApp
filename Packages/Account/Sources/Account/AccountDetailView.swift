import DesignSystem
import EmojiText
import Env
import Models
import Network
import Shimmer
import Status
import SwiftUI

@MainActor
public struct AccountDetailView: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.redactionReasons) private var reasons

  @Environment(StreamWatcher.self) private var watcher
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(UserPreferences.self) private var preferences
  @Environment(Theme.self) private var theme
  @Environment(Client.self) private var client
  @Environment(RouterPath.self) private var routerPath

  @State private var viewModel: AccountDetailViewModel
  @State private var isCurrentUser: Bool = false
  @State private var showBlockConfirmation: Bool = false

  @State private var isEditingAccount: Bool = false
  @State private var isEditingFilters: Bool = false
  @State private var isEditingRelationshipNote: Bool = false

  @Binding var scrollToTopSignal: Int

  /// When coming from a URL like a mention tap in a status.
  public init(accountId: String, scrollToTopSignal: Binding<Int>) {
    _viewModel = .init(initialValue: .init(accountId: accountId))
    _scrollToTopSignal = scrollToTopSignal
  }

  /// When the account is already fetched by the parent caller.
  public init(account: Account, scrollToTopSignal: Binding<Int>) {
    _viewModel = .init(initialValue: .init(account: account))
    _scrollToTopSignal = scrollToTopSignal
  }

  public var body: some View {
    ScrollViewReader { proxy in
      List {
        makeHeaderView(proxy: proxy)
          .applyAccountDetailsRowStyle(theme: theme)
          .padding(.bottom, -20)
          .id(ScrollToView.Constants.scrollToTop)
        familiarFollowers
          .applyAccountDetailsRowStyle(theme: theme)
        featuredTagsView
          .applyAccountDetailsRowStyle(theme: theme)

        Picker("", selection: $viewModel.selectedTab) {
          ForEach(isCurrentUser ? AccountDetailViewModel.Tab.currentAccountTabs : AccountDetailViewModel.Tab.accountTabs,
                  id: \.self)
          { tab in
            Image(systemName: tab.iconName)
              .tag(tab)
              .accessibilityLabel(tab.accessibilityLabel)
          }
        }
        .pickerStyle(.segmented)
        .padding(.layoutPadding)
        .applyAccountDetailsRowStyle(theme: theme)
        .id("status")

        switch viewModel.tabState {
        case .statuses:
          if viewModel.selectedTab == .statuses {
            pinnedPostsView
          }
          StatusesListView(fetcher: viewModel,
                           client: client,
                           routerPath: routerPath)
        case .followedTags:
          tagsListView
        case .lists:
          listsListView
        }
      }
      .environment(\.defaultMinListRowHeight, 1)
      .listStyle(.plain)
      #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
      #endif
      .onChange(of: scrollToTopSignal) {
        withAnimation {
          proxy.scrollTo(ScrollToView.Constants.scrollToTop, anchor: .top)
        }
      }
    }
    .onAppear {
      guard reasons != .placeholder else { return }
      isCurrentUser = currentAccount.account?.id == viewModel.accountId
      viewModel.isCurrentUser = isCurrentUser
      viewModel.client = client

      // Avoid capturing non-Sendable `self` just to access the view model.
      let viewModel = viewModel
      Task {
        await withTaskGroup(of: Void.self) { group in
          group.addTask { await viewModel.fetchAccount() }
          group.addTask {
            if await viewModel.statuses.isEmpty {
              await viewModel.fetchNewestStatuses()
            }
          }
          if !viewModel.isCurrentUser {
            group.addTask { await viewModel.fetchFamilliarFollowers() }
          }
        }
      }
    }
    .refreshable {
      Task {
        SoundEffectManager.shared.playSound(.pull)
        HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.3))
        await viewModel.fetchAccount()
        await viewModel.fetchNewestStatuses()
        HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.7))
        SoundEffectManager.shared.playSound(.refresh)
      }
    }
    .onChange(of: watcher.latestEvent?.id) {
      if let latestEvent = watcher.latestEvent,
         viewModel.accountId == currentAccount.account?.id
      {
        viewModel.handleEvent(event: latestEvent, currentAccount: currentAccount)
      }
    }
    .onChange(of: isEditingAccount) { _, newValue in
      if !newValue {
        Task {
          await viewModel.fetchAccount()
          await preferences.refreshServerPreferences()
        }
      }
    }
    .sheet(isPresented: $isEditingAccount, content: {
      EditAccountView()
    })
    .sheet(isPresented: $isEditingFilters, content: {
      FiltersListView()
    })
    .sheet(isPresented: $isEditingRelationshipNote, content: {
      EditRelationshipNoteView(accountDetailViewModel: viewModel)
    })
    .edgesIgnoringSafeArea(.top)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      toolbarContent
    }
  }

  @ViewBuilder
  private func makeHeaderView(proxy: ScrollViewProxy?) -> some View {
    switch viewModel.accountState {
    case .loading:
      AccountDetailHeaderView(viewModel: viewModel,
                              account: .placeholder(),
                              scrollViewProxy: proxy)
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    case let .data(account):
      AccountDetailHeaderView(viewModel: viewModel,
                              account: account,
                              scrollViewProxy: proxy)
    case let .error(error):
      Text("Error: \(error.localizedDescription)")
    }
  }

  @ViewBuilder
  private var featuredTagsView: some View {
    if !viewModel.featuredTags.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 4) {
          if !viewModel.featuredTags.isEmpty {
            ForEach(viewModel.featuredTags) { tag in
              Button {
                routerPath.navigate(to: .hashTag(tag: tag.name, account: viewModel.accountId))
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
  private var familiarFollowers: some View {
    if !viewModel.familiarFollowers.isEmpty {
      VStack(alignment: .leading, spacing: 2) {
        Text("account.detail.familiar-followers")
          .font(.scaledHeadline)
          .padding(.leading, .layoutPadding)
          .accessibilityAddTraits(.isHeader)
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(spacing: 0) {
            ForEach(viewModel.familiarFollowers) { account in
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

  private var tagsListView: some View {
    Group {
      ForEach(currentAccount.sortedTags) { tag in
        HStack {
          TagRowView(tag: tag)
          Spacer()
          Image(systemName: "chevron.right")
        }
        #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
        #endif
      }
    }.task {
      await currentAccount.fetchFollowedTags()
    }
  }

  private var listsListView: some View {
    Group {
      ForEach(currentAccount.sortedLists) { list in
        NavigationLink(value: RouterDestination.list(list: list)) {
          Text(list.title)
            .font(.scaledHeadline)
            .foregroundColor(theme.labelColor)
        }
        #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
        #endif
        .contextMenu {
          Button("account.list.delete", role: .destructive) {
            Task {
              await currentAccount.deleteList(list: list)
            }
          }
        }
      }
      Button("account.list.create") {
        routerPath.presentedSheet = .listCreate
      }
      .tint(theme.tintColor)
      .buttonStyle(.borderless)
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
    .task {
      await currentAccount.fetchLists()
    }
  }

  @ViewBuilder
  private var pinnedPostsView: some View {
    if !viewModel.pinned.isEmpty {
      Label("account.post.pinned", systemImage: "pin.fill")
        .accessibilityAddTraits(.isHeader)
        .font(.scaledFootnote)
        .foregroundStyle(.secondary)
        .fontWeight(.semibold)
        .listRowInsets(.init(top: 0,
                             leading: 12,
                             bottom: 0,
                             trailing: .layoutPadding))
        .listRowSeparator(.hidden)
        #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
        #endif
      ForEach(viewModel.pinned) { status in
        StatusRowView(viewModel: .init(status: status, client: client, routerPath: routerPath))
      }
      Rectangle()
        .fill(theme.secondaryBackgroundColor)
        .frame(height: 12)
        .listRowInsets(.init())
        .listRowSeparator(.hidden)
        .accessibilityHidden(true)
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItemGroup(placement: .navigationBarTrailing) {
      if !viewModel.isCurrentUser {
        Button {
          if let account = viewModel.account {
            routerPath.presentedSheet = .mentionStatusEditor(account: account,
                                                             visibility: preferences.postVisibility)
          }
        } label: {
          Image(systemName: "arrowshape.turn.up.left")
        }
      }

      Menu {
        AccountDetailContextMenu(showBlockConfirmation: $showBlockConfirmation, viewModel: viewModel)

        if !viewModel.isCurrentUser {
          Button {
            isEditingRelationshipNote = true
          } label: {
            Label("account.relation.note.edit", systemImage: "pencil")
          }
        }

        if isCurrentUser {
          Button {
            isEditingAccount = true
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
              isEditingFilters = true
            } label: {
              Label("account.action.edit-filters", systemImage: "line.3.horizontal.decrease.circle")
            }
          }

          Button {
            routerPath.presentedSheet = .accountPushNotficationsSettings
          } label: {
            Label("settings.push.navigation-title", systemImage: "bell")
          }

          if let account = viewModel.account {
            Divider()

            Button {
              if let url = URL(string: "https://mastometrics.com/auth/login?username=\(account.acct)@\(client.server)&instance=\(client.server)&auto=true") {
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
        Image(systemName: "ellipsis.circle")
          .accessibilityLabel("accessibility.tabs.profile.options.label")
          .accessibilityInputLabels([
            LocalizedStringKey("accessibility.tabs.profile.options.label"),
            LocalizedStringKey("accessibility.tabs.profile.options.inputLabel1"),
            LocalizedStringKey("accessibility.tabs.profile.options.inputLabel2"),
          ])
      }
      .confirmationDialog("Block User", isPresented: $showBlockConfirmation) {
        if let account = viewModel.account {
          Button("account.action.block-user-\(account.username)", role: .destructive) {
            Task {
              do {
                viewModel.relationship = try await client.post(endpoint: Accounts.block(id: account.id))
              } catch {
                print("Error while blocking: \(error.localizedDescription)")
              }
            }
          }
        }
      } message: {
        Text("account.action.block-user-confirmation")
      }
    }
  }
}

extension View {
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
    AccountDetailView(account: .placeholder(), scrollToTopSignal: .constant(0))
  }
}
