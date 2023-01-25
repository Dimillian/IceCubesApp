import DesignSystem
import Env
import Models
import Network
import Shimmer
import SwiftUI

public struct AccountsListView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentAccount: CurrentAccount
  @StateObject private var viewModel: AccountsListViewModel
  @State private var didAppear: Bool = false

  public init(mode: AccountsListMode) {
    _viewModel = StateObject(wrappedValue: .init(mode: mode))
  }

  public var body: some View {
    List {
      switch viewModel.state {
      case .loading:
        ForEach(Account.placeholders()) { _ in
          AccountsListRow(viewModel: .init(account: .placeholder(), relationShip: .placeholder()))
            .redacted(reason: .placeholder)
            .shimmering()
            .listRowBackground(theme.primaryBackgroundColor)
        }
      case let .display(accounts, relationships, nextPageState):
        if case .followers = viewModel.mode,
           !currentAccount.followRequests.isEmpty
        {
          Section(
            header: Text("account.follow-requests.pending-requests"),
            footer: Text("account.follow-requests.instructions")
              .font(.scaledFootnote)
              .foregroundColor(.secondary)
              .offset(y: -8)
          ) {
            ForEach(currentAccount.followRequests) { account in
              AccountsListRow(
                viewModel: .init(account: account),
                isFollowRequest: true,
                requestUpdated: {
                  Task {
                    await viewModel.fetch()
                  }
                }
              )
              .listRowBackground(theme.primaryBackgroundColor)
            }
          }
        }
        Section {
          ForEach(accounts) { account in
            if let relationship = relationships.first(where: { $0.id == account.id }) {
              AccountsListRow(viewModel: .init(account: account,
                                               relationShip: relationship))
                .listRowBackground(theme.primaryBackgroundColor)
            }
          }
        }

        switch nextPageState {
        case .hasNextPage:
          loadingRow
            .listRowBackground(theme.primaryBackgroundColor)
            .onAppear {
              Task {
                await viewModel.fetchNextPage()
              }
            }

        case .loadingNextPage:
          loadingRow
            .listRowBackground(theme.primaryBackgroundColor)
        case .none:
          EmptyView()
        }

      case let .error(error):
        Text(error.localizedDescription)
          .listRowBackground(theme.primaryBackgroundColor)
      }
    }
    .scrollContentBackground(.hidden)
    .background(theme.primaryBackgroundColor)
    .listStyle(.plain)
    .navigationTitle(viewModel.mode.title)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      viewModel.client = client
      guard !didAppear else { return }
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
