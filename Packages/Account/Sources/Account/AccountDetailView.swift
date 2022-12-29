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
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routeurPath: RouterPath
  
  @StateObject private var viewModel: AccountDetailViewModel
  @State private var scrollOffset: CGFloat = 0
  @State private var isFieldsSheetDisplayed: Bool = false
  @State private var isCurrentUser: Bool = false
  
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
            if isCurrentUser {
              Picker("", selection: $viewModel.selectedTab) {
                ForEach(AccountDetailViewModel.Tab.allCases, id: \.self) { tab in
                  Text(tab.title).tag(tab)
                }
              }
              .pickerStyle(.segmented)
              .padding(.horizontal, DS.Constants.layoutPadding)
              .offset(y: -20)
            } else {
              Divider()
                .offset(y: -20)
            }
          }
          .id("status")
          
          switch viewModel.tabState {
          case .statuses:
            StatusesListView(fetcher: viewModel)
          case let .followedTags(tags):
            makeTagsListView(tags: tags)
          }
        }
      }
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
    .edgesIgnoringSafeArea(.top)
    .navigationTitle(Text(scrollOffset < -200 ? viewModel.title : ""))
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
        .padding(.leading, DS.Constants.layoutPadding)
      }
    }
  }
  
  @ViewBuilder
  private var familliarFollowers: some View {
    if !viewModel.familliarFollowers.isEmpty {
      VStack(alignment: .leading, spacing: 2) {
        Text("Also followed by")
          .font(.headline)
          .padding(.leading, DS.Constants.layoutPadding)
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
          .padding(.leading, DS.Constants.layoutPadding + 4)
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
    }
  }
  
  private func makeTagsListView(tags: [Tag]) -> some View {
    Group {
      ForEach(tags) { tag in
        TagRowView(tag: tag)
          .padding(.horizontal, DS.Constants.layoutPadding)
          .padding(.vertical, 8)
      }
    }
  }
}

struct AccountDetailView_Previews: PreviewProvider {
  static var previews: some View {
    AccountDetailView(account: .placeholder())
  }
}

