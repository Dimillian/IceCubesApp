import SwiftUI
import Models
import Network
import Status
import Shimmer
import DesignSystem

public struct AccountDetailView: View {
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel: AccountDetailViewModel
  
  public init(accountId: String) {
    _viewModel = StateObject(wrappedValue: .init(accountId: accountId))
  }
  
  public init(account: Account) {
    _viewModel = StateObject(wrappedValue: .init(account: account))
  }
  
  public var body: some View {
    ScrollView {
      LazyVStack {
        headerView
        statusesView
          .padding(.horizontal, 16)
      }
    }
    .edgesIgnoringSafeArea(.top)
    .task {
      viewModel.client = client
      await viewModel.fetchAccount()
      await viewModel.fetchStatuses()
    }
  }
  
  @ViewBuilder
  private var headerView: some View {
    switch viewModel.state {
    case .loading:
      AccountDetailHeaderView(account: .placeholder())
        .redacted(reason: .placeholder)
    case let .data(account):
      AccountDetailHeaderView(account: account)
    case let .error(error):
      Text("Error: \(error.localizedDescription)")
    }
    
  }
  
  @ViewBuilder
  private var statusesView: some View {
    switch viewModel.statusesState {
    case .loading:
      ForEach(Status.placeholders()) { status in
        StatusRowView(status: status)
          .redacted(reason: .placeholder)
          .shimmering()
        Divider()
      }
    case let .error(error):
      Text(error.localizedDescription)
    case let .display(statuses, nextPageState):
      ForEach(statuses) { status in
        StatusRowView(status: status)
        Divider()
          .padding(.bottom, DS.Constants.layoutPadding)
      }
      
      switch nextPageState {
      case .hasNextPage:
        loadingRow
          .onAppear {
            Task {
              await viewModel.loadNextPage()
            }
          }
      case .loadingNextPage:
        loadingRow
      }
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

struct AccountDetailView_Previews: PreviewProvider {
  static var previews: some View {
    AccountDetailView(account: .placeholder())
  }
}

