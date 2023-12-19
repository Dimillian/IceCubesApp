import DesignSystem
import Env
import Models
import Network
import Shimmer
import SwiftUI

@MainActor
public struct NotificationsListView: View {
  @Environment(\.scenePhase) private var scenePhase
  @Environment(Theme.self) private var theme
  @Environment(StreamWatcher.self) private var watcher
  @Environment(Client.self) private var client
  @Environment(RouterPath.self) private var routerPath
  @Environment(CurrentAccount.self) private var account
  @State private var viewModel = NotificationsViewModel()
  @Binding var scrollToTopSignal: Int

  let lockedType: Models.Notification.NotificationType?

  public init(lockedType: Models.Notification.NotificationType?, scrollToTopSignal: Binding<Int>) {
    self.lockedType = lockedType
    _scrollToTopSignal = scrollToTopSignal
  }

  public var body: some View {
    ScrollViewReader { proxy in
      List {
        scrollToTopView
        topPaddingView
        notificationsView
      }
      .id(account.account?.id)
      .environment(\.defaultMinListRowHeight, 1)
      .listStyle(.plain)
      .onChange(of: scrollToTopSignal) {
        withAnimation {
          proxy.scrollTo(ScrollToView.Constants.scrollToTop, anchor: .top)
        }
      }
    }
    .onAppear { viewModel.loadSelectedType() }
    .toolbar {
      ToolbarItem(placement: .principal) {
        let title = lockedType?.menuTitle() ?? viewModel.selectedType?.menuTitle() ?? "notifications.navigation-title"
        if lockedType == nil {
          Text(title)
            .font(.headline)
            .accessibilityRepresentation {
              Menu(title) {}
            }
            .accessibilityAddTraits(.isHeader)
            .accessibilityRemoveTraits(.isButton)
            .accessibilityRespondsToUserInteraction(true)
        } else {
          Text(title)
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
        }
      }
    }
    .toolbar {
      if lockedType == nil {
        ToolbarTitleMenu {
          Button {
            viewModel.selectedType = nil
          } label: {
            Label("notifications.navigation-title", systemImage: "bell.fill")
          }
          Divider()
          ForEach(Notification.NotificationType.allCases, id: \.self) { type in
            Button {
              viewModel.selectedType = type
            } label: {
              Label {
                Text(type.menuTitle())
              } icon: {
                type.icon(isPrivate: false)
              }
            }
          }
        }
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    #if !os(visionOS)
    .scrollContentBackground(.hidden)
    .background(theme.primaryBackgroundColor)
    #endif
    .task {
      viewModel.client = client
      viewModel.currentAccount = account
      if let lockedType {
        viewModel.selectedType = lockedType
      }
      await viewModel.fetchNotifications()
    }
    .refreshable {
      SoundEffectManager.shared.playSound(.pull)
      HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.3))
      await viewModel.fetchNotifications()
      HapticManager.shared.fireHaptic(.dataRefresh(intensity: 0.7))
      SoundEffectManager.shared.playSound(.refresh)
    }
    .onChange(of: watcher.latestEvent?.id) {
      if let latestEvent = watcher.latestEvent {
        viewModel.handleEvent(event: latestEvent)
      }
    }
    .onChange(of: scenePhase) { _, newValue in
      switch newValue {
      case .active:
        Task {
          await viewModel.fetchNotifications()
        }
      default:
        break
      }
    }
  }

  @ViewBuilder
  private var notificationsView: some View {
    switch viewModel.state {
    case .loading:
      ForEach(ConsolidatedNotification.placeholders()) { notification in
        NotificationRowView(notification: notification,
                            client: client,
                            routerPath: routerPath,
                            followRequests: account.followRequests)
          .listRowInsets(.init(top: 12,
                               leading: .layoutPadding + 4,
                               bottom: 12,
                               trailing: .layoutPadding))
          #if os(visionOS)
          .listRowBackground(RoundedRectangle(cornerRadius: 8)
            .foregroundStyle(Material.regular))
          #else
           .listRowBackground(theme.primaryBackgroundColor)
          #endif
          .redacted(reason: .placeholder)
          .allowsHitTesting(false)
      }

    case let .display(notifications, nextPageState):
      if notifications.isEmpty {
        EmptyView(iconName: "bell.slash",
                  title: "notifications.empty.title",
                  message: "notifications.empty.message")
          #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor)
          #endif
          .listSectionSeparator(.hidden)
      } else {
        ForEach(notifications) { notification in
          NotificationRowView(notification: notification,
                              client: client,
                              routerPath: routerPath,
                              followRequests: account.followRequests)
            .listRowInsets(.init(top: 12,
                                 leading: .layoutPadding + 4,
                                 bottom: 12,
                                 trailing: .layoutPadding))
            #if os(visionOS)
            .listRowBackground(RoundedRectangle(cornerRadius: 8)
              .foregroundStyle(notification.type == .mention && lockedType != .mention ? Material.thick : Material.regular))
            #else
            .listRowBackground(notification.type == .mention && lockedType != .mention ?
              theme.secondaryBackgroundColor : theme.primaryBackgroundColor)
            #endif
            .id(notification.id)
        }
      }

      switch nextPageState {
      case .none:
        EmptyView()
      case .hasNextPage:
        loadingRow
          .onAppear {
            Task {
              await viewModel.fetchNextPage()
            }
          }
      case .loadingNextPage:
        loadingRow
      }

    case .error:
      ErrorView(title: "notifications.error.title",
                message: "notifications.error.message",
                buttonTitle: "action.retry")
      {
        Task {
          await viewModel.fetchNotifications()
        }
      }
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
      #endif
      .listSectionSeparator(.hidden)
    }
  }

  private var loadingRow: some View {
    HStack {
      Spacer()
      ProgressView()
      Spacer()
    }
    .listRowInsets(.init(top: .layoutPadding,
                         leading: .layoutPadding + 4,
                         bottom: .layoutPadding,
                         trailing: .layoutPadding))
    #if !os(visionOS)
    .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  private var topPaddingView: some View {
    HStack {}
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)
      .listRowInsets(.init())
      .frame(height: .layoutPadding)
      .accessibilityHidden(true)
  }

  private var scrollToTopView: some View {
    ScrollToView()
      .frame(height: .scrollToViewHeight)
      .onAppear {
        viewModel.scrollToTopVisible = true
      }
      .onDisappear {
        viewModel.scrollToTopVisible = false
      }
  }
}
