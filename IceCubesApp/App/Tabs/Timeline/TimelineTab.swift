import AppAccount
import Combine
import DesignSystem
import Env
import Models
import Network
import SwiftUI
import Timeline

struct TimelineTab: View {
  @EnvironmentObject private var appAccount: AppAccountsManager
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var client: Client
  @StateObject private var routerPath = RouterPath()
  @Binding var popToRootTab: Tab

  @State private var didAppear: Bool = false
  @State private var timeline: TimelineFilter
  @State private var scrollToTopSignal: Int = 0

  @AppStorage("last_timeline_filter") public var lastTimelineFilter: TimelineFilter = .home

  private let canFilterTimeline: Bool

  init(popToRootTab: Binding<Tab>, timeline: TimelineFilter? = nil) {
    canFilterTimeline = timeline == nil
    self.timeline = timeline ?? .home
    _popToRootTab = popToRootTab
  }

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      TimelineView(timeline: $timeline, scrollToTopSignal: $scrollToTopSignal)
        .withAppRouter()
        .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
        .toolbar {
          toolbarView
        }
        .toolbarBackground(theme.primaryBackgroundColor.opacity(0.50), for: .navigationBar)
        .id(client.id)
    }
    .onAppear {
      routerPath.client = client
      if !didAppear && canFilterTimeline {
        didAppear = true
        if client.isAuth {
          timeline = lastTimelineFilter
        } else {
          timeline = .federated
        }
      }
      Task {
        await currentAccount.fetchLists()
      }
      if !client.isAuth {
        routerPath.presentedSheet = .addAccount
      }
    }
    .onChange(of: client.isAuth, perform: { _ in
      if client.isAuth {
        timeline = lastTimelineFilter
      } else {
        timeline = .federated
      }
    })
    .onChange(of: currentAccount.account?.id, perform: { _ in
      if client.isAuth, canFilterTimeline {
        timeline = lastTimelineFilter
      } else {
        timeline = .federated
      }
    })
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .timeline {
        if routerPath.path.isEmpty {
          scrollToTopSignal += 1
        } else {
          routerPath.path = []
        }
      }
    }
    .onChange(of: client.id) { _ in
      routerPath.path = []
    }
    .onChange(of: timeline) { timeline in
      if timeline == .home || timeline == .federated || timeline == .local {
        lastTimelineFilter = timeline
      }
    }
    .withSafariRouter()
    .environmentObject(routerPath)
  }

  @ViewBuilder
  private var timelineFilterButton: some View {
    if timeline == .home {
      Button {
        self.timeline = .latest
      } label: {
        Label(TimelineFilter.latest.localizedTitle(), systemImage: TimelineFilter.latest.iconName() ?? "")
      }
      .keyboardShortcut("r", modifiers: .command)
      Divider()
    }
    ForEach(TimelineFilter.availableTimeline(client: client), id: \.self) { timeline in
      Button {
        self.timeline = timeline
      } label: {
        Label(timeline.localizedTitle(), systemImage: timeline.iconName() ?? "")
      }
    }
    if !currentAccount.lists.isEmpty {
      Menu("timeline.filter.lists") {
        ForEach(currentAccount.sortedLists) { list in
          Button {
            timeline = .list(list: list)
          } label: {
            Label(list.title, systemImage: "list.bullet")
          }
        }
      }
    }

    if !currentAccount.tags.isEmpty {
      Menu("timeline.filter.tags") {
        ForEach(currentAccount.sortedTags) { tag in
          Button {
            timeline = .hashtag(tag: tag.name, accountId: nil)
          } label: {
            Label("#\(tag.name)", systemImage: "number")
          }
        }
      }
    }

    Menu("timeline.filter.local") {
      ForEach(preferences.remoteLocalTimelines, id: \.self) { server in
        Button {
          timeline = .remoteLocal(server: server, filter: .local)
        } label: {
          VStack {
            Label(server, systemImage: "dot.radiowaves.right")
          }
        }
      }
      Button {
        routerPath.presentedSheet = .addRemoteLocalTimeline
      } label: {
        Label("timeline.filter.add-local", systemImage: "badge.plus.radiowaves.right")
      }
    }
  }

  private var addAccountButton: some View {
    Button {
      routerPath.presentedSheet = .addAccount
    } label: {
      Image(systemName: "person.badge.plus")
    }
    .accessibilityLabel("accessibility.tabs.timeline.add-account")
  }

  @ToolbarContentBuilder
  private var toolbarView: some ToolbarContent {
    if canFilterTimeline {
      ToolbarTitleMenu {
        timelineFilterButton
      }
    }
    if client.isAuth {
      if UIDevice.current.userInterfaceIdiom != .pad {
        ToolbarItem(placement: .navigationBarLeading) {
          AppAccountsSelectorView(routerPath: routerPath)
            .id(currentAccount.account?.id)
        }
      }
      statusEditorToolbarItem(routerPath: routerPath,
                              visibility: preferences.postVisibility)
    } else {
      ToolbarItem(placement: .navigationBarTrailing) {
        addAccountButton
      }
    }
    switch timeline {
    case let .list(list):
      ToolbarItem {
        Button {
          routerPath.presentedSheet = .listEdit(list: list)
        } label: {
          Image(systemName: "list.bullet")
        }
      }
    case let .remoteLocal(server, _):
      ToolbarItem {
        Menu {
          ForEach(RemoteTimelineFilter.allCases, id: \.self) { filter in
            Button {
              timeline = .remoteLocal(server: server, filter: filter)
            } label: {
              Label(filter.localizedTitle(), systemImage: filter.iconName())
            }
          }
        } label: {
          Image(systemName: "line.3.horizontal.decrease.circle")
        }
      }
    default:
      ToolbarItem {
        EmptyView()
      }
    }
  }
}
