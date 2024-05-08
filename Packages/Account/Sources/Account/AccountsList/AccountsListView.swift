import DesignSystem
import Env
import Models
import Network
import SwiftUI

@MainActor
public struct AccountsListView: View {
  @Environment(Theme.self) private var theme
  @Environment(Client.self) private var client
  @Environment(CurrentAccount.self) private var currentAccount
  @State private var viewModel: AccountsListViewModel
  @State private var didAppear: Bool = false

  public init(mode: AccountsListMode) {
    _viewModel = .init(initialValue: .init(mode: mode))
  }

  public var body: some View {
    listView
    #if !os(visionOS)
    .scrollContentBackground(.hidden)
    .background(theme.primaryBackgroundColor)
    #endif
    .listStyle(.plain)
    .toolbar {
      ToolbarItem(placement: .principal) {
        VStack {
          Text(viewModel.mode.title)
            .font(.headline)
          if let count = viewModel.totalCount {
            Text(String(count))
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .navigationTitle(viewModel.mode.title)
    .navigationBarTitleDisplayMode(.inline)
    .task {
      viewModel.client = client
      guard !didAppear else { return }
      didAppear = true
      await viewModel.fetch()
    }
  }

  @ViewBuilder
  private var listView: some View {
    if currentAccount.account?.id == viewModel.accountId {
      searchableList
    } else {
      standardList
        .refreshable {
          await viewModel.fetch()
        }
    }
  }

  private var searchableList: some View {
    List {
      listContent
    }
    .searchable(text: $viewModel.searchQuery,
                placement: .navigationBarDrawer(displayMode: .always))
    .task(id: viewModel.searchQuery) {
      if !viewModel.searchQuery.isEmpty {
        await viewModel.search()
      }
    }
    .onChange(of: viewModel.searchQuery) { _, newValue in
      if newValue.isEmpty {
        Task {
          await viewModel.fetch()
        }
      }
    }
  }

  private var standardList: some View {
    List {
      listContent
    }
  }

  @ViewBuilder
  private var listContent: some View {
    switch viewModel.state {
    case .loading:
      ForEach(Account.placeholders()) { _ in
        AccountsListRow(viewModel: .init(account: .placeholder(), relationShip: .placeholder()))
          .redacted(reason: .placeholder)
          .allowsHitTesting(false)
        #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor)
        #endif
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
            #if !os(visionOS)
            .listRowBackground(theme.primaryBackgroundColor)
            #endif
          }
        }
      }
      Section {
        if accounts.isEmpty {
          PlaceholderView(iconName: "person.icloud",
                          title: "No accounts found",
                          message: "This list of accounts is empty")
          .listRowSeparator(.hidden)
        } else {
          ForEach(accounts) { account in
            if let relationship = relationships.first(where: { $0.id == account.id }) {
              AccountsListRow(viewModel: .init(account: account,
                                               relationShip: relationship))
            }
          }
        }
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif

      switch nextPageState {
      case .hasNextPage:
        NextPageView {
          try await viewModel.fetchNextPage()
        }
        #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
        #endif

      case .none:
        EmptyView()
      }

    case let .error(error):
      Text(error.localizedDescription)
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
  }
}

#Preview {
  List {
    AccountsListRow(viewModel: .init(account: .placeholder(),
                                     relationShip: .placeholder()))
  }
  .listStyle(.plain)
  .withPreviewsEnv()
  .environment(Theme.shared)
}
