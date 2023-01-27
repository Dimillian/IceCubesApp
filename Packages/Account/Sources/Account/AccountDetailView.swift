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
  @EnvironmentObject private var curretnInstance: CurrentInstance
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routerPath: RouterPath

  @StateObject private var viewModel: AccountDetailViewModel
  @State private var scrollOffset: CGFloat = 0
  @State private var isFieldsSheetDisplayed: Bool = false
  @State private var isCurrentUser: Bool = false
  @State private var isCreateListAlertPresented: Bool = false
  @State private var createListTitle: String = ""

  @State private var isEditingAccount: Bool = false
  @State private var isEditingFilters: Bool = false

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
      ScrollViewOffsetReader { offset in
        self.scrollOffset = offset
      } content: {
        LazyVStack(alignment: .leading) {
          makeHeaderView(proxy: proxy)
          familiarFollowers
            .offset(y: -36)
          featuredTagsView
            .offset(y: -36)
          Group {
            Picker("", selection: $viewModel.selectedTab) {
              ForEach(isCurrentUser ? AccountDetailViewModel.Tab.currentAccountTabs : AccountDetailViewModel.Tab.accountTabs,
                      id: \.self) { tab in
                Image(systemName: tab.iconName)
                  .tag(tab)
              }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, .layoutPadding)
            .offset(y: -20)
          }
          .id("status")

          switch viewModel.tabState {
          case .statuses:
            if viewModel.selectedTab == .statuses {
              pinnedPostsView
            }
            StatusesListView(fetcher: viewModel)
          case .followedTags:
            tagsListView
          case .lists:
            listsListView
          }
        }
        .frame(maxWidth: .maxColumnWidth)
      }
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
    }
    .onAppear {
      guard reasons != .placeholder else { return }
      isCurrentUser = currentAccount.account?.id == viewModel.accountId
      viewModel.isCurrentUser = isCurrentUser
      viewModel.client = client
      Task {
        await withTaskGroup(of: Void.self) { group in
          group.addTask { await viewModel.fetchAccount() }
          group.addTask {
            if await viewModel.statuses.isEmpty {
              await viewModel.fetchStatuses()
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
        await viewModel.fetchAccount()
        await viewModel.fetchStatuses()
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
                              scrollViewProxy: proxy,
                              scrollOffset: $scrollOffset)
        .redacted(reason: .placeholder)
        .shimmering()
    case let .data(account):
      AccountDetailHeaderView(viewModel: viewModel,
                              account: account,
                              scrollViewProxy: proxy,
                              scrollOffset: $scrollOffset)
    case let .error(error):
      Text("Error: \(error.localizedDescription)")
    }
  }

  @ViewBuilder
  private var featuredTagsView: some View {
    if !viewModel.featuredTags.isEmpty || !viewModel.fields.isEmpty {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 4) {
          if !viewModel.fields.isEmpty {
            Button {
              isFieldsSheetDisplayed.toggle()
            } label: {
              VStack(alignment: .leading, spacing: 0) {
                Text("account.detail.about")
                  .font(.scaledCallout)
                Text("account.detail.n-fields \(viewModel.fields.count)")
                  .font(.caption2)
              }
            }
            .buttonStyle(.bordered)
            .sheet(isPresented: $isFieldsSheetDisplayed) {
              fieldSheetView
            }
          }
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

  private var fieldSheetView: some View {
    NavigationStack {
      List {
        ForEach(viewModel.fields) { field in
          VStack(alignment: .leading, spacing: 2) {
            Text(field.name)
              .font(.scaledHeadline)
            HStack {
              if field.verifiedAt != nil {
                Image(systemName: "checkmark.seal")
                  .foregroundColor(Color.green.opacity(0.80))
              }
              EmojiTextApp(field.value, emojis: viewModel.account?.emojis ?? [])
                .foregroundColor(theme.tintColor)
            }
            .font(.scaledBody)
          }
          .listRowBackground(field.verifiedAt != nil ? Color.green.opacity(0.15) : theme.primaryBackgroundColor)
        }
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .navigationTitle("account.detail.about")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            isFieldsSheetDisplayed = false
          } label: {
            Image(systemName: "xmark")
              .imageScale(.small)
              .font(.body.weight(.semibold))
              .frame(width: 30, height: 30)
              .background(theme.primaryBackgroundColor.opacity(0.5))
              .clipShape(Circle())
          }
          .foregroundColor(theme.tintColor)
        }
      }
    }
  }

  private var tagsListView: some View {
    Group {
      ForEach(currentAccount.tags) { tag in
        HStack {
          TagRowView(tag: tag)
          Spacer()
          Image(systemName: "chevron.right")
        }
        .padding(.horizontal, .layoutPadding)
        .padding(.vertical, 8)
      }
    }.task {
      await currentAccount.fetchFollowedTags()
    }
  }

  private var listsListView: some View {
    Group {
      ForEach(currentAccount.lists) { list in
        NavigationLink(value: RouterDestinations.list(list: list)) {
          HStack {
            Text(list.title)
            Spacer()
            Image(systemName: "chevron.right")
          }
          .padding(.vertical, 8)
          .padding(.horizontal, .layoutPadding)
          .font(.scaledHeadline)
          .foregroundColor(theme.labelColor)
        }
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
      .padding(.horizontal, .layoutPadding)
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
      ForEach(viewModel.pinned) { status in
        VStack(alignment: .leading) {
          Label("account.post.pinned", systemImage: "pin.fill")
            .font(.scaledFootnote)
            .foregroundColor(.gray)
            .fontWeight(.semibold)
          StatusRowView(viewModel: .init(status: status))
        }
        .padding(.horizontal, .layoutPadding)
        Divider()
          .padding(.vertical, .dividerPadding)
      }
    }
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem(placement: .principal) {
      if scrollOffset < -200 {
        switch viewModel.accountState {
        case let .data(account):
          EmojiTextApp(.init(stringValue: account.safeDisplayName), emojis: account.emojis)
            .font(.scaledHeadline)
        default:
          EmptyView()
        }
      }
    }

    ToolbarItem(placement: .navigationBarTrailing) {
      Menu {
        if let account = viewModel.account {
          Section(account.acct) {
            if !viewModel.isCurrentUser {
              Button {
                routerPath.presentedSheet = .mentionStatusEditor(account: account,
                                                                 visibility: preferences.postVisibility)
              } label: {
                Label("account.action.mention", systemImage: "at")
              }
              Button {
                routerPath.presentedSheet = .mentionStatusEditor(account: account, visibility: .direct)
              } label: {
                Label("account.action.message", systemImage: "tray.full")
              }

              Divider()

              if viewModel.relationship?.blocking == true {
                Button {
                  Task {
                    do {
                      viewModel.relationship = try await client.post(endpoint: Accounts.unblock(id: account.id))
                    } catch {
                      print("Error while unblocking: \(error.localizedDescription)")
                    }
                  }
                } label: {
                  Label("account.action.unblock", systemImage: "person.crop.circle.badge.exclamationmark")
                }
              } else {
                Button {
                  Task {
                    do {
                      viewModel.relationship = try await client.post(endpoint: Accounts.block(id: account.id))
                    } catch {
                      print("Error while blocking: \(error.localizedDescription)")
                    }
                  }
                } label: {
                  Label("account.action.block", systemImage: "person.crop.circle.badge.xmark")
                }
              }
              if viewModel.relationship?.muting == true {
                Button {
                  Task {
                    do {
                      viewModel.relationship = try await client.post(endpoint: Accounts.unmute(id: account.id))
                    } catch {
                      print("Error while unmuting: \(error.localizedDescription)")
                    }
                  }
                } label: {
                  Label("account.action.unmute", systemImage: "speaker")
                }
              } else {
                Button {
                  Task {
                    do {
                      viewModel.relationship = try await client.post(endpoint: Accounts.mute(id: account.id))
                    } catch {
                      print("Error while muting: \(error.localizedDescription)")
                    }
                  }
                } label: {
                  Label("account.action.mute", systemImage: "speaker.slash")
                }
              }

              if let relationship = viewModel.relationship,
                 relationship.following
              {
                if relationship.notifying {
                  Button {
                    Task {
                      do {
                        viewModel.relationship = try await client.post(endpoint: Accounts.unmute(id: account.id))
                      } catch {
                        print("Error while disabling notifications: \(error.localizedDescription)")
                      }
                    }
                  } label: {
                    Label("account.action.notify-disable", systemImage: "bell.fill")
                  }
                } else {
                  Button {
                    Task {
                      do {
                        viewModel.relationship = try await client.post(endpoint: Accounts.mute(id: account.id))
                      } catch {
                        print("Error while enabling notifications: \(error.localizedDescription)")
                      }
                    }
                  } label: {
                    Label("account.action.notify-enable", systemImage: "bell")
                  }
                }
                if relationship.showingReblogs {
                  Button {
                    Task {
                      do {
                        viewModel.relationship = try await client.post(endpoint: Accounts.follow(id: account.id,
                                                                                                 notify: relationship.notifying,
                                                                                                 reblogs: false))
                      } catch {
                        print("Error while disabling reboosts: \(error.localizedDescription)")
                      }
                    }
                  } label: {
                    Label("account.action.reboosts-hide", systemImage: "arrow.left.arrow.right.circle.fill")
                  }
                } else {
                  Button {
                    Task {
                      do {
                        viewModel.relationship = try await client.post(endpoint: Accounts.follow(id: account.id,
                                                                                                 notify: relationship.notifying,
                                                                                                 reblogs: true))
                      } catch {
                        print("Error while enabling reboosts: \(error.localizedDescription)")
                      }
                    }
                  } label: {
                    Label("account.action.reboosts-show", systemImage: "arrow.left.arrow.right.circle")
                  }
                }
              }

              Divider()
            }

            if viewModel.relationship?.following == true {
              Button {
                routerPath.presentedSheet = .listAddAccount(account: account)
              } label: {
                Label("account.action.add-remove-list", systemImage: "list.bullet")
              }
            }

            if let url = account.url {
              ShareLink(item: url)
              Button { UIApplication.shared.open(url) } label: {
                Label("status.action.view-in-browser", systemImage: "safari")
              }
            }

            Divider()

            if isCurrentUser {
              Button {
                isEditingAccount = true
              } label: {
                Label("account.action.edit-info", systemImage: "pencil")
              }

              if curretnInstance.isFiltersSupported {
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
            }
          }
        }
      } label: {
        if scrollOffset < -40 {
          Image(systemName: "ellipsis.circle")
        } else {
          Image(systemName: "ellipsis.circle.fill")
        }
      }
    }
  }
}

struct AccountDetailView_Previews: PreviewProvider {
  static var previews: some View {
    AccountDetailView(account: .placeholder())
  }
}
