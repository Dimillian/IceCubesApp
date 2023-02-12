import DesignSystem
import Env
import Models
import Network
import Shimmer
import SwiftUI

public struct StatusDetailView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routerPath: RouterPath
  @Environment(\.openURL) private var openURL
  @StateObject private var viewModel: StatusDetailViewModel
  @State private var isLoaded: Bool = false
  @State private var statusHeight: CGFloat = 0

  public init(statusId: String) {
    _viewModel = StateObject(wrappedValue: .init(statusId: statusId))
  }

  public init(status: Status) {
    _viewModel = StateObject(wrappedValue: .init(status: status))
  }

  public init(remoteStatusURL: URL) {
    _viewModel = StateObject(wrappedValue: .init(remoteStatusURL: remoteStatusURL))
  }

  public var body: some View {
    GeometryReader { reader in
      ScrollViewReader { proxy in
        List {
          if isLoaded {
            topPaddingView
          }

          switch viewModel.state {
          case .loading:
            loadingDetailView

          case let .display(status, context, date):
            if !context.ancestors.isEmpty {
              ForEach(context.ancestors) { ancestor in
                StatusRowView(viewModel: .init(status: ancestor, isCompact: false))
              }
            }

            makeCurrentStatusView(status: status)
              .id(date)

            if !context.descendants.isEmpty {
              ForEach(context.descendants) { descendant in
                StatusRowView(viewModel: .init(status: descendant, isCompact: false))
              }
            }

            if !isLoaded {
              loadingContextView
            }

            Rectangle()
              .foregroundColor(theme.secondaryBackgroundColor)
              .frame(minHeight: reader.frame(in: .local).size.height - statusHeight)
              .listRowSeparator(.hidden)
              .listRowBackground(theme.secondaryBackgroundColor)
              .listRowInsets(.init())

          case .error:
            errorView
          }
        }
        .environment(\.defaultMinListRowHeight, 1)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(theme.primaryBackgroundColor)
        .onChange(of: viewModel.scrollToId, perform: { scrollToId in
          if let scrollToId {
            viewModel.scrollToId = nil
            proxy.scrollTo(scrollToId, anchor: .top)
          }
        })
        .task {
          guard !isLoaded else { return }
          viewModel.client = client
          let result = await viewModel.fetch()
          isLoaded = true

          if !result {
            if let url = viewModel.remoteStatusURL {
              openURL(url)
            }
            DispatchQueue.main.async {
              _ = routerPath.path.popLast()
            }
          }
        }
      }
      .onChange(of: watcher.latestEvent?.id) { _ in
        guard let lastEvent = watcher.latestEvent else { return }
        viewModel.handleEvent(event: lastEvent, currentAccount: currentAccount.account)
      }
    }
    .navigationTitle(viewModel.title)
    .navigationBarTitleDisplayMode(.inline)
  }

  private func makeCurrentStatusView(status: Status) -> some View {
    StatusRowView(viewModel: .init(status: status,
                                   isCompact: false,
                                   isFocused: true))
      .overlay {
        GeometryReader { reader in
          VStack {}
            .onAppear {
              statusHeight = reader.size.height
            }
        }
      }
      .id(status.id)
  }

  private var errorView: some View {
    ErrorView(title: "status.error.title",
              message: "status.error.message",
              buttonTitle: "action.retry") {
      Task {
        await viewModel.fetch()
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
    .listRowSeparator(.hidden)
  }

  private var loadingDetailView: some View {
    ForEach(Status.placeholders()) { status in
      StatusRowView(viewModel: .init(status: status, isCompact: false))
        .redacted(reason: .placeholder)
    }
  }

  private var loadingContextView: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
    .frame(height: 50)
    .listRowSeparator(.hidden)
    .listRowBackground(theme.secondaryBackgroundColor)
    .listRowInsets(.init())
  }

  private var topPaddingView: some View {
    HStack { EmptyView() }
      .listRowBackground(theme.primaryBackgroundColor)
      .listRowSeparator(.hidden)
      .listRowInsets(.init())
      .frame(height: .layoutPadding)
  }
}
