import SwiftUI
import Models
import Network

public struct AccountDetailView: View {
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel: AccountDetailViewModel
  
  public init(accountId: String) {
    _viewModel = StateObject(wrappedValue: .init(accountId: accountId))
  }
  
  public var body: some View {
    List {
      switch viewModel.state {
      case .loading:
        loadingRow
      case let .data(account):
        Text("Account id \(account.id)")
        Text("Account name \(account.displayName)")
      case let .error(error):
        Text("Error: \(error.localizedDescription)")
      }
    }
    .task {
      viewModel.client = client
      await viewModel.fetchAccount()
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
