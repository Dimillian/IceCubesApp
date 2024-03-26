import DesignSystem
import Env
import Models
import Network
import SwiftUI

@MainActor
public struct StatusDetailView: View {
  @Environment(Theme.self) private var theme
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(StreamWatcher.self) private var watcher
  @Environment(Client.self) private var client
  @Environment(RouterPath.self) private var routerPath
  @Environment(\.isCompact) private var isCompact: Bool
  @Environment(UserPreferences.self) private var userPreferences: UserPreferences

  @State private var viewModel: StatusDetailViewModel

  @State private var isLoaded: Bool = false
  @State private var statusHeight: CGFloat = 0

  /// April 4th, 2023: Without explicit focus being set, VoiceOver will skip over a seemingly random number of elements on this screen when pushing in from the main timeline.
  /// By using ``@AccessibilityFocusState`` and setting focus once, we work around this issue.
  @AccessibilityFocusState private var initialFocusBugWorkaround: Bool

  public init(statusId: String) {
    _viewModel = .init(wrappedValue: .init(statusId: statusId))
  }

  public init(status: Status) {
    _viewModel = .init(wrappedValue: .init(status: status))
  }

  public init(remoteStatusURL: URL) {
    _viewModel = .init(wrappedValue: .init(remoteStatusURL: remoteStatusURL))
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

          case let .display(statuses):
            makeStatusesListView(statuses: statuses)

            if !isLoaded {
              loadingContextView
            }

            #if !os(visionOS)
              Rectangle()
                .foregroundColor(theme.secondaryBackgroundColor)
                .frame(minHeight: reader.frame(in: .local).size.height - statusHeight)
                .listRowSeparator(.hidden)
                .listRowBackground(theme.secondaryBackgroundColor)
                .listRowInsets(.init())
                .accessibilityHidden(true)
            #endif

          case .error:
            errorView
          }
        }
        .environment(\.defaultMinListRowHeight, 1)
        .listStyle(.plain)
        #if !os(visionOS)
          .scrollContentBackground(.hidden)
          .background(theme.primaryBackgroundColor)
        #endif
          .onChange(of: viewModel.scrollToId) { _, newValue in
            if let newValue {
              viewModel.scrollToId = nil
              proxy.scrollTo(newValue, anchor: .top)
            }
          }
          .onAppear {
            guard !isLoaded else { return }
            viewModel.client = client
            viewModel.routerPath = routerPath
            Task {
              let result = await viewModel.fetch()
              isLoaded = true

              if !result {
                if let url = viewModel.remoteStatusURL {
                  await UIApplication.shared.open(url)
                }
                DispatchQueue.main.async {
                  _ = routerPath.path.popLast()
                }
              }
            }
          }
      }
      .refreshable {
        Task {
          await viewModel.fetch()
        }
      }
      .onChange(of: watcher.latestEvent?.id) {
        guard let lastEvent = watcher.latestEvent else { return }
        viewModel.handleEvent(event: lastEvent, currentAccount: currentAccount.account)
      }
    }
    .navigationTitle(viewModel.title)
    .navigationBarTitleDisplayMode(.inline)
  }

  private func makeStatusesListView(statuses: [Status]) -> some View {
    ForEach(statuses) { status in
      let (indentationLevel, extraInsets) = viewModel.getIndentationLevel(id: status.id, maxIndent: userPreferences.getRealMaxIndent())
      let viewModel: StatusRowViewModel = .init(status: status,
                                                client: client,
                                                routerPath: routerPath,
                                                scrollToId: $viewModel.scrollToId)
      let isFocused = self.viewModel.statusId == status.id

      StatusRowView(viewModel: viewModel, context: .detail)
        .id(status.id + (status.editedAt?.asDate.description ?? ""))
        .environment(\.extraLeadingInset, !isCompact ? extraInsets : 0)
        .environment(\.indentationLevel, !isCompact ? indentationLevel : 0)
        .environment(\.isStatusFocused, isFocused)
        .overlay {
          if isFocused {
            GeometryReader { reader in
              VStack {}
                .onAppear {
                  statusHeight = reader.size.height
                }
            }
          }
        }
      #if !os(visionOS)
        .listRowBackground(viewModel.highlightRowColor)
      #endif
        .listRowInsets(.init(top: 12,
                             leading: .layoutPadding,
                             bottom: 12,
                             trailing: .layoutPadding))
    }
  }

  private var errorView: some View {
    ErrorView(title: "status.error.title",
              message: "status.error.message",
              buttonTitle: "action.retry")
    {
      _ = await viewModel.fetch()
    }
    #if !os(visionOS)
    .listRowBackground(theme.primaryBackgroundColor)
    #endif
    .listRowSeparator(.hidden)
  }

  private var loadingDetailView: some View {
    ForEach(Status.placeholders()) { status in
      StatusRowView(viewModel: .init(status: status, client: client, routerPath: routerPath))
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
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
    #if !os(visionOS)
      .listRowBackground(theme.secondaryBackgroundColor)
    #endif
      .listRowInsets(.init())
  }

  private var topPaddingView: some View {
    HStack { EmptyView() }
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif
      .listRowSeparator(.hidden)
      .listRowInsets(.init())
      .frame(height: .layoutPadding)
      .accessibilityHidden(true)
  }
}
