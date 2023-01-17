import SwiftUI
import Timeline
import Env
import Network
import Combine
import DesignSystem
import Models
import AppAccount

struct TimelineTab: View {
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
        .id(currentAccount.account?.id)
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
      timeline = client.isAuth ? .home : .federated
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
    .withSafariRouteur()
    .environmentObject(routerPath)
  }
  
  
  @ViewBuilder
  private var timelineFilterButton: some View {
    ForEach(TimelineFilter.availableTimeline(client: client), id: \.self) { timeline in
      Button {
        self.timeline = timeline
      } label: {
        Label(timeline.title(), systemImage: timeline.iconName() ?? "")
      }
    }
    if !currentAccount.lists.isEmpty {
      Menu("Lists") {
        ForEach(currentAccount.lists) { list in
          Button {
            timeline = .list(list: list)
          } label: {
            Label(list.title, systemImage: "list.bullet")
          }
        }
      }
    }
    
    if !currentAccount.tags.isEmpty {
      Menu("Followed Tags") {
        ForEach(currentAccount.tags) { tag in
          Button {
            timeline = .hashtag(tag: tag.name, accountId: nil)
          } label: {
            Label("#\(tag.name)", systemImage: "number")
          }
        }
      }
    }
    
    Menu("Local Timelines") {
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
        Label("Add a local timeline", systemImage: "badge.plus.radiowaves.right")
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
        }
      }
      statusEditorToolbarItem(routerPath: routerPath,
                              visibility: preferences.serverPreferences?.postVisibility ?? .pub)
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
