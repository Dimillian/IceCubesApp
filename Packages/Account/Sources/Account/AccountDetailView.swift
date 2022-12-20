import SwiftUI
import Models
import Network
import Status
import Shimmer
import DesignSystem

public struct AccountDetailView: View {
  @Environment(\.redactionReasons) private var reasons
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel: AccountDetailViewModel
  @State private var scrollOffset: CGFloat = 0
  
  private let isCurrentUser: Bool
  
  public init(accountId: String) {
    _viewModel = StateObject(wrappedValue: .init(accountId: accountId))
    isCurrentUser = false
  }
  
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
        Divider()
          .offset(y: -20)
        StatusesListView(fetcher: viewModel)
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
    switch viewModel.state {
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
}

struct AccountDetailView_Previews: PreviewProvider {
  static var previews: some View {
    AccountDetailView(account: .placeholder())
  }
}

