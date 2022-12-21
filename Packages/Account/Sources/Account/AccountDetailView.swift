import SwiftUI
import Models
import Network
import Status
import Shimmer
import DesignSystem
import Routeur

public struct AccountDetailView: View {  
  @Environment(\.redactionReasons) private var reasons
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routeurPath: RouterPath
  
  @StateObject private var viewModel: AccountDetailViewModel
  @State private var scrollOffset: CGFloat = 0
  
  private let isCurrentUser: Bool
  
  /// When coming from a URL like a mention tap in a status.
  public init(accountId: String) {
    _viewModel = StateObject(wrappedValue: .init(accountId: accountId))
    isCurrentUser = false
  }
  
  /// When the account is already fetched by the parent caller.
  public init(account: Account, isCurrentUser: Bool = false) {
    _viewModel = StateObject(wrappedValue: .init(account: account,
                                                 isCurrentUser: isCurrentUser))
    self.isCurrentUser = isCurrentUser
  }
  
  public var body: some View {
    ScrollViewOffsetReader { offset in
      self.scrollOffset = offset
    } content: {
      LazyVStack {
        headerView
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
        
        switch viewModel.tabState {
        case .statuses:
          StatusesListView(fetcher: viewModel)
        case let .followedTags(tags):
          makeTagsListView(tags: tags)
        }
      }
    }
    .task {
      guard reasons != .placeholder else { return }
      viewModel.client = client
      await viewModel.fetchAccount()
      if viewModel.statuses.isEmpty {
        await viewModel.fetchStatuses()
      }
    }
    .refreshable {
      Task {
        await viewModel.fetchAccount()
        await viewModel.fetchStatuses()
      }
    }
    .edgesIgnoringSafeArea(.top)
    .navigationTitle(Text(scrollOffset < -20 ? viewModel.title : ""))
  }
  
  @ViewBuilder
  private var headerView: some View {
    switch viewModel.accountState {
    case .loading:
      AccountDetailHeaderView(isCurrentUser: isCurrentUser,
                              account: .placeholder(),
                              relationship: .constant(.placeholder()),
                              following: .constant(false))
        .redacted(reason: .placeholder)
    case let .data(account):
      AccountDetailHeaderView(isCurrentUser: isCurrentUser,
                              account: account,
                              relationship: $viewModel.relationship,
                              following:
      .init(get: {
        viewModel.relationship?.following ?? false
      }, set: { following in
        Task {
          if following {
            await viewModel.follow()
          } else {
            await viewModel.unfollow()
          }
        }
      }))
    case let .error(error):
      Text("Error: \(error.localizedDescription)")
    }
  }
  
  private func makeTagsListView(tags: [Tag]) -> some View {
    Group {
      ForEach(tags) { tag in
        HStack {
          VStack(alignment: .leading) {
            Text("#\(tag.name)")
              .font(.headline)
            Text("\(tag.totalUses) posts from \(tag.totalAccounts) participants")
              .font(.footnote)
              .foregroundColor(.gray)
          }
          Spacer()
        }
        .padding(.horizontal, DS.Constants.layoutPadding)
        .padding(.vertical, 8)
        .onTapGesture {
          routeurPath.navigate(to: .hashTag(tag: tag.name))
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

