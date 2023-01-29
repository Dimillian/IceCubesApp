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
        .id(appAccount.currentAccount.id)
    }
    .onAppear {
      routerPath.client = client
      if !didAppear && canFilterTimeline {
        didAppear = true
        timeline = client.isAuth ? .home : .federated
      }
      Task {
        await currentAccount.fetchLists()
      }
      if !client.isAuth {
        routerPath.presentedSheet = .addAccount
      }
    }
    .onChange(of: client.isAuth, perform: { isAuth in
      timeline = isAuth ? .home : .federated
    })
    .onChange(of: currentAccount.account?.id, perform: { _ in
      timeline = client.isAuth && canFilterTimeline ? .home : .federated
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
    .onChange(of: currentAccount.account?.id) { _ in
      routerPath.path = []
    }
    .withSafariRouter()
    .environmentObject(routerPath)
  }

  @ViewBuilder
  private var timelineFilterButton: some View {
    ForEach(TimelineFilter.availableTimeline(client: client), id: \.self) { timeline in
      Button {
        self.timeline = timeline
      } label: {
        Label(timeline.localizedTitle(), systemImage: timeline.iconName() ?? "")
      }
    }
    if !currentAccount.lists.isEmpty {
      let sortedLists = currentAccount.lists.sorted { $0.title.lowercased() < $1.title.lowercased() }
      Menu("timeline.filter.lists") {
        ForEach(sortedLists) { list in
          Button {
            timeline = .list(list: list)
          } label: {
            Label(list.title, systemImage: "list.bullet")
          }
        }
      }
    }

    if !currentAccount.tags.isEmpty {
      let sortedTags = currentAccount.tags.sorted { $0.name.lowercased() < $1.name.lowercased() }
      Menu("timeline.filter.tags") {
        ForEach(sortedTags) { tag in
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
          timeline = .remoteLocal(server: server)
        } label: {
          Label(server, systemImage: "dot.radiowaves.right")
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
    case let .remoteLocal(server):
      ToolbarItem {
        Button {
          preferences.remoteLocalTimelines.removeAll(where: { $0 == server })
          timeline = client.isAuth ? .home : .federated
        } label: {
          Image(systemName: "pin.slash")
        }
      }
    default:
      ToolbarItem {
        EmptyView()
      }
    }
  }
}
