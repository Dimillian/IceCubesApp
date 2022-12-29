import SwiftUI
import Models
import Shimmer
import Env
import Network
import DesignSystem

public struct StatusDetailView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var routeurPath: RouterPath
  @StateObject private var viewModel: StatusDetailViewModel
  @State private var isLoaded: Bool = false
    
  public init(statusId: String) {
    _viewModel = StateObject(wrappedValue: .init(statusId: statusId))
  }
  
  public var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack {
          switch viewModel.state {
          case .loading:
            ForEach(Status.placeholders()) { status in
              StatusRowView(viewModel: .init(status: status, isEmbed: false))
                .redacted(reason: .placeholder)
                .shimmering()
            }
          case let.display(status, context):
            if !context.ancestors.isEmpty {
              ForEach(context.ancestors) { ancestor in
                StatusRowView(viewModel: .init(status: ancestor, isEmbed: false))
                Divider()
                  .padding(.vertical, DS.Constants.dividerPadding)
              }
            }
            StatusRowView(viewModel: .init(status: status,
                                           isEmbed: false,
                                           isFocused: true))
              .id(status.id)
            Divider()
              .padding(.bottom, DS.Constants.dividerPadding * 2)
            if !context.descendants.isEmpty {
              ForEach(context.descendants) { descendant in
                StatusRowView(viewModel: .init(status: descendant, isEmbed: false))
                Divider()
                  .padding(.vertical, DS.Constants.dividerPadding)
              }
            }
            
          case let .error(error):
            Text(error.localizedDescription)
          }
        }
        .padding(.horizontal, DS.Constants.layoutPadding)
        .padding(.top, DS.Constants.layoutPadding)
      }
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
      .task {
        guard !isLoaded else { return }
        isLoaded = true
        viewModel.client = client
        await viewModel.fetchStatusDetail()
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
