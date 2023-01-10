import SwiftUI
import Models
import Network
import Status
import Shimmer
import DesignSystem
import Env

public struct AccountDetailView: View {  
  @Environment(\.redactionReasons) private var reasons
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routeurPath: RouterPath
  
  @StateObject private var viewModel: AccountDetailViewModel
  @State private var scrollOffset: CGFloat = 0
  @State private var isFieldsSheetDisplayed: Bool = false
  @State private var isCurrentUser: Bool = false
  @State private var isCreateListAlertPresented: Bool = false
  @State private var createListTitle: String = ""
  @State private var isEditingAccount: Bool = false
  
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
          familliarFollowers
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
      Task {
        guard reasons != .placeholder else { return }
        isCurrentUser = currentAccount.account?.id == viewModel.accountId
        viewModel.isCurrentUser = isCurrentUser
        viewModel.client = client
        await viewModel.fetchAccount()
        if viewModel.statuses.isEmpty {
          await viewModel.fetchStatuses()
        }
      }
    }
    .refreshable {
      Task {
        await viewModel.fetchAccount()
        await viewModel.fetchStatuses()
      }
    }
    .onChange(of: watcher.latestEvent?.id) { id in
      if let latestEvent = watcher.latestEvent,
          viewModel.accountId == currentAccount.account?.id {
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
      AccountDetailHeaderView(isCurrentUser: isCurrentUser,
                              account: .placeholder(),
                              relationship: .placeholder(),
                              scrollViewProxy: proxy,
                              scrollOffset: $scrollOffset)
        .redacted(reason: .placeholder)
        .shimmering()
    case let .data(account):
      AccountDetailHeaderView(isCurrentUser: isCurrentUser,
                              account: account,
                              relationship: viewModel.relationship,
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
                Text("About")
                  .font(.callout)
                Text("\(viewModel.fields.count) fields")
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
                routeurPath.navigate(to: .hashTag(tag: tag.name, account: viewModel.accountId))
              } label: {
                VStack(alignment: .leading, spacing: 0) {
                  Text("#\(tag.name)")
                    .font(.callout)
                  Text("\(tag.statusesCount) posts")
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
  private var familliarFollowers: some View {
    if !viewModel.familliarFollowers.isEmpty {
      VStack(alignment: .leading, spacing: 2) {
        Text("Also followed by")
          .font(.headline)
          .padding(.leading, .layoutPadding)
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(spacing: 0) {
            ForEach(viewModel.familliarFollowers) { account in
              AvatarView(url: account.avatar, size: .badge)
                .onTapGesture {
                  routeurPath.navigate(to: .accountDetailWithAccount(account: account))
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
              .font(.headline)
            HStack {
              if field.verifiedAt != nil {
                Image(systemName: "checkmark.seal")
                  .foregroundColor(Color.green.opacity(0.80))
              }
              Text(field.value.asSafeAttributedString)
                .foregroundColor(theme.tintColor)
            }
            .font(.body)
          }
          .listRowBackground(field.verifiedAt != nil ? Color.green.opacity(0.15) : theme.primaryBackgroundColor)
        }
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .navigationTitle("About")
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
        NavigationLink(value: RouteurDestinations.list(list: list)) {
          HStack {
            Text(list.title)
            Spacer()
            Image(systemName: "chevron.right")
          }
          .padding(.vertical, 8)
          .padding(.horizontal, .layoutPadding)
          .font(.headline)
          .foregroundColor(theme.labelColor)
        }
        .contextMenu {
          Button("Delete list", role: .destructive) {
            Task {
              await currentAccount.deleteList(list: list)
            }
          }
        }
      }
      Button("Create a new list") {
        isCreateListAlertPresented = true
      }
      .padding(.horizontal, .layoutPadding)
    }
    .task {
      await currentAccount.fetchLists()
    }
    .alert("Create a new list", isPresented: $isCreateListAlertPresented) {
      TextField("List name", text: $createListTitle)
      Button("Cancel") {
        isCreateListAlertPresented = false
        createListTitle = ""
      }
      Button("Create List") {
        guard !createListTitle.isEmpty else { return }
        isCreateListAlertPresented = false
        Task {
          await currentAccount.createList(title: createListTitle)
          createListTitle = ""
        }
      }
    } message: {
      Text("Enter the name for your list")
    }
  }
  
  @ViewBuilder
  private var pinnedPostsView: some View {
    if !viewModel.pinned.isEmpty {
      ForEach(viewModel.pinned) { status in
        VStack(alignment: .leading) {
          Label("Pinned post", systemImage: "pin.fill")
            .font(.footnote)
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
          account.displayNameWithEmojis.font(.headline)
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
                routeurPath.presentedSheet = .mentionStatusEditor(account: account,
                                                                  visibility: preferences.serverPreferences?.postVisibility ?? .pub)
              } label: {
                Label("Mention", systemImage: "at")
              }
              Button {
                routeurPath.presentedSheet = .mentionStatusEditor(account: account, visibility: .direct)
              } label: {
                Label("Message", systemImage: "tray.full")
              }
              Divider()
            }
            
            if viewModel.relationship?.following == true {
              Button {
                routeurPath.presentedSheet = .listAddAccount(account: account)
              } label: {
                Label("Add/Remove from lists", systemImage: "list.bullet")
              }
            }
            
            if let url = account.url {
              ShareLink(item: url)
            }
            
            Divider()
            
            if isCurrentUser {
              Button {
                isEditingAccount = true
              } label: {
                Label("Edit Info", systemImage: "pencil")
              }
            }
          }
        }
      } label: {
        Image(systemName: "ellipsis")
      }
    }
  }
}

struct AccountDetailView_Previews: PreviewProvider {
  static var previews: some View {
    AccountDetailView(account: .placeholder())
  }
}

