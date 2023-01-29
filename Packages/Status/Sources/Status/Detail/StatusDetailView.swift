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
  
  public init(statusId: String) {
    _viewModel = StateObject(wrappedValue: .init(statusId: statusId))
  }
  
  public init(remoteStatusURL: URL) {
    _viewModel = StateObject(wrappedValue: .init(remoteStatusURL: remoteStatusURL))
  }
  
  public var body: some View {
    ScrollViewReader { proxy in
      ZStack {
        ScrollView {
          LazyVStack {
            Group {
              switch viewModel.state {
              case .loading:
                ForEach(Status.placeholders()) { status in
                  StatusRowView(viewModel: .init(status: status, isCompact: false))
                    .padding(.horizontal, .layoutPadding)
                    .redacted(reason: .placeholder)
                    .shimmering()
                  Divider()
                    .padding(.vertical, .dividerPadding)
                }
              case let .display(status, context):
                if !context.ancestors.isEmpty {
                  ForEach(context.ancestors) { ancestor in
                    StatusRowView(viewModel: .init(status: ancestor, isCompact: false))
                      .padding(.horizontal, .layoutPadding)
                    Divider()
                      .padding(.vertical, .dividerPadding)
                  }
                }
                StatusRowView(viewModel: .init(status: status,
                                               isCompact: false,
                                               isFocused: true))
                .padding(.horizontal, .layoutPadding)
                .id(status.id)
                Divider()
                  .padding(.bottom, .dividerPadding * 2)
                if !context.descendants.isEmpty {
                  ForEach(context.descendants) { descendant in
                    StatusRowView(viewModel: .init(status: descendant, isCompact: false))
                      .padding(.horizontal, .layoutPadding)
                    Divider()
                      .padding(.vertical, .dividerPadding)
                  }
                }
                
              case .error:
                ErrorView(title: "status.error.title",
                          message: "status.error.message",
                          buttonTitle: "action.retry") {
                  Task {
                    await viewModel.fetch()
                  }
                }
              }
            }
            .frame(maxWidth: .maxColumnWidth)
          }
          .padding(.top, .layoutPadding)
        }
        .background(theme.primaryBackgroundColor)
      }
      .task {
        guard !isLoaded else { return }
        isLoaded = true
        viewModel.client = client
        let result = await viewModel.fetch()
        if !result {
          if let url = viewModel.remoteStatusURL {
            openURL(url)
          }
          DispatchQueue.main.async {
            _ = routerPath.path.popLast()
          }
        }
        DispatchQueue.main.async {
          proxy.scrollTo(viewModel.statusId, anchor: .center)
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
}
