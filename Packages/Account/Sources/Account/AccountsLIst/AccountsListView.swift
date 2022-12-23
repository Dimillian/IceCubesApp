import SwiftUI
import Network
import Models
import Env
import Shimmer

public struct AccountsListView: View {
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel: AccountsListViewModel
  @State private var didAppear: Bool = false
  
  public init(accountId: String, mode: AccountsListMode) {
    _viewModel = StateObject(wrappedValue: .init(accountId: accountId, mode: mode))
  }
  
  public var body: some View {
    List {
      switch viewModel.state {
      case .loading:
        ForEach(Account.placeholders()) { account in
          AccountsListRow(viewModel: .init(account: .placeholder(), relationShip: .placeholder()))
            .redacted(reason: .placeholder)
            .shimmering()
        }
      case let .display(accounts, relationships, nextPageState):
        ForEach(accounts) { account in
          if let relationship = relationships.first(where: { $0.id == account.id }) {
            AccountsListRow(viewModel: .init(account: account,
                                             relationShip: relationship))
          }
        }
        
        switch nextPageState {
        case .hasNextPage:
          loadingRow
            .onAppear {
              Task {
                await viewModel.fetchNextPage()
              }
            }
          
        case .loadingNextPage:
          loadingRow
        case .none:
          EmptyView()
        }
        
      case let .error(error):
        Text(error.localizedDescription)
      }
    }
    .listStyle(.plain)
    .navigationTitle(viewModel.mode.rawValue.capitalized)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      viewModel.client = client
      guard !didAppear else { return}
      didAppear = true
      await viewModel.fetch()
    }
  }
  
  private var loadingRow: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
  }
}
