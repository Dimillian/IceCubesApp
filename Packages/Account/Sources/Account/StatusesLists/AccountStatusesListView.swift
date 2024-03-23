import DesignSystem
import Env
import Models
import Network
import StatusKit
import SwiftUI

@MainActor
public struct AccountStatusesListView: View {
  @Environment(Theme.self) private var theme
  @Environment(Client.self) private var client
  @Environment(RouterPath.self) private var routerPath

  @State private var viewModel: AccountStatusesListViewModel
  @State private var isLoaded = false

  public init(mode: AccountStatusesListViewModel.Mode) {
    _viewModel = .init(initialValue: .init(mode: mode))
  }

  public var body: some View {
    List {
      StatusesListView(fetcher: viewModel, client: client, routerPath: routerPath)
    }
    .listStyle(.plain)
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
    #endif
      .navigationTitle(viewModel.mode.title)
      .navigationBarTitleDisplayMode(.inline)
      .refreshable {
        await viewModel.fetchNewestStatuses(pullToRefresh: true)
      }
      .task {
        guard !isLoaded else { return }
        viewModel.client = client
        await viewModel.fetchNewestStatuses(pullToRefresh: false)
        isLoaded = true
      }
      .onChange(of: client.id) { _, _ in
        isLoaded = false
        viewModel.client = client
        Task {
          await viewModel.fetchNewestStatuses(pullToRefresh: false)
          isLoaded = true
        }
      }
  }
}
