import DesignSystem
import EmojiText
import Env
import Models
import Network
import Shimmer
import Status
import SwiftUI

public struct AccountDetailView: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.redactionReasons) private var reasons

  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var currentInstance: CurrentInstance
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routerPath: RouterPath

  @StateObject private var viewModel: AccountDetailViewModel
  @State private var isCurrentUser: Bool = false
  @State private var isCreateListAlertPresented: Bool = false
  @State private var createListTitle: String = ""

  @State private var isEditingAccount: Bool = false
  @State private var isEditingFilters: Bool = false
  @State private var isEditingRelationshipNote: Bool = false

  /// When coming from a URL like a mention tap in a status.
  public init(accountId: String) {
    _viewModel = StateObject(wrappedValue: .init(accountId: accountId))
  }

  /// When the account is already fetched by the parent caller.
  public init(account: Account) {
    _viewModel = StateObject(wrappedValue: .init(account: account))
  }

  public var body: some View {
    ScrollViewReader { proxy in
      List {
        makeHeaderView(proxy: proxy)
          .applyAccountDetailsRowStyle(theme: theme)
          .padding(.bottom, -20)
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
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
    }
    .onAppear {
      guard reasons != .placeholder else { return }
      isCurrentUser = currentAccount.account?.id == viewModel.accountId
      viewModel.isCurrentUser = isCurrentUser
      viewModel.client = client

      // Avoid capturing non-Sendable `self` just to access the view model.
      let viewModel = self.viewModel
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
        SoundEffectManager.shared.playSound(of: .pull)
        HapticManager.shared.fireHaptic(of: .dataRefresh(intensity: 0.3))
        await viewModel.fetchAccount()
        await viewModel.fetchNewestStatuses()
        HapticManager.shared.fireHaptic(of: .dataRefresh(intensity: 0.7))
        SoundEffectManager.shared.playSound(of: .refresh)
      }
    }
    .onChange(of: watcher.latestEvent?.id) { _ in
      if let latestEvent = watcher.latestEvent,
         viewModel.accountId == currentAccount.account?.id
      {
        viewModel.handleEvent(event: latestEvent, currentAccount: currentAccount)
      }
    }
    .onChange(of: isEditingAccount, perform: { isEditing in
      if !isEditing {
        Task {
          await viewModel.fetchAccount()
          await preferences.refreshServerPreferences()
        }
      }
    })
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
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(spacing: 0) {
            ForEach(viewModel.familiarFollowers) { account in
              AvatarView(url: account.avatar, size: .badge)
                .onTapGesture {
                  routerPath.navigate(to: .accountDetailWithAccount(account: account))
                }
                .padding(.leading, -4)
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
        .listRowBackground(theme.primaryBackgroundColor)
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
        .listRowBackground(theme.primaryBackgroundColor)
        .contextMenu {
          Button("account.list.delete", role: .destructive) {
            Task {
              await currentAccount.deleteList(list: list)
            }
          }
        }
      }
      Button("account.list.create") {
        isCreateListAlertPresented = true
      }
      .tint(theme.tintColor)
      .buttonStyle(.borderless)
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .task {
      await currentAccount.fetchLists()
    }
    .alert("account.list.create", isPresented: $isCreateListAlertPresented) {
      TextField("account.list.name", text: $createListTitle)
      Button("action.cancel") {
        isCreateListAlertPresented = false
        createListTitle = ""
      }
      Button("account.list.create.confirm") {
        guard !createListTitle.isEmpty else { return }
        isCreateListAlertPresented = false
        Task {
          await currentAccount.createList(title: createListTitle)
          createListTitle = ""
        }
      }
    } message: {
      Text("account.list.create.description")
    }
  }

  @ViewBuilder
  private var pinnedPostsView: some View {
    if !viewModel.pinned.isEmpty {
      Label("account.post.pinned", systemImage: "pin.fill")
        .font(.scaledFootnote)
        .foregroundColor(.gray)
        .fontWeight(.semibold)
        .listRowInsets(.init(top: 0,
                             leading: 12,
                             bottom: 0,
                             trailing: .layoutPadding))
        .listRowSeparator(.hidden)
        .listRowBackground(theme.primaryBackgroundColor)
      ForEach(viewModel.pinned) { status in
        StatusRowView(viewModel: { .init(status: status, client: client, routerPath: routerPath) })
      }
      Rectangle()
        .fill(theme.secondaryBackgroundColor)
        .frame(height: 12)
        .listRowInsets(.init())
        .listRowSeparator(.hidden)
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Menu {
        AccountDetailContextMenu(viewModel: viewModel)

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
            LocalizedStringKey("accessibility.tabs.profile.options.inputLabel2")
          ])
      }
    }
  }
}

extension View {
  func applyAccountDetailsRowStyle(theme: Theme) -> some View {
    listRowInsets(.init())
      .listRowSeparator(.hidden)
      .listRowBackground(theme.primaryBackgroundColor)
  }
}

struct AccountDetailView_Previews: PreviewProvider {
  static var previews: some View {
    AccountDetailView(account: .placeholder())
  }
}
