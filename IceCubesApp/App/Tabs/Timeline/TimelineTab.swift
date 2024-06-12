import AppAccount
import Combine
import DesignSystem
import Env
import Models
import Network
import SwiftData
import SwiftUI
import Timeline

@MainActor
struct TimelineTab: View {
  @Environment(\.modelContext) private var context

  @Environment(AppAccountsManager.self) private var appAccount
  @Environment(Theme.self) private var theme
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(UserPreferences.self) private var preferences
  @Environment(Client.self) private var client
  @State private var routerPath = RouterPath()
  @Binding var popToRootTab: Tab

  @State private var didAppear: Bool = false
  @State private var timeline: TimelineFilter = .home
  @State private var selectedTagGroup: TagGroup?
  @State private var scrollToTopSignal: Int = 0

  @Query(sort: \LocalTimeline.creationDate, order: .reverse) var localTimelines: [LocalTimeline]
  @Query(sort: \TagGroup.creationDate, order: .reverse) var tagGroups: [TagGroup]

  @AppStorage("last_timeline_filter") var lastTimelineFilter: TimelineFilter = .home
  @AppStorage("timeline_pinned_filters") private var pinnedFilters: [TimelineFilter] = []

  private let canFilterTimeline: Bool

  init(popToRootTab: Binding<Tab>, timeline: TimelineFilter? = nil) {
    canFilterTimeline = timeline == nil
    _popToRootTab = popToRootTab
    _timeline = .init(initialValue: timeline ?? .home)
  }

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      TimelineView(timeline: $timeline,
                   pinnedFilters: $pinnedFilters,
                   selectedTagGroup: $selectedTagGroup,
                   scrollToTopSignal: $scrollToTopSignal,
                   canFilterTimeline: canFilterTimeline)
        .withAppRouter()
        .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
        .toolbar {
          toolbarView
        }
        .toolbarBackground(theme.primaryBackgroundColor.opacity(0.30), for: .navigationBar)
        .id(client.id)
    }
    .onAppear {
      routerPath.client = client
      if !didAppear, canFilterTimeline {
        didAppear = true
        if client.isAuth {
          timeline = lastTimelineFilter
        } else {
          timeline = .trending
        }
      }
      Task {
        await currentAccount.fetchLists()
      }
      if !client.isAuth {
        routerPath.presentedSheet = .addAccount
      }
    }
    .onChange(of: client.isAuth) {
      resetTimelineFilter()
    }
    .onChange(of: currentAccount.account?.id) {
      resetTimelineFilter()
    }
    .onChange(of: $popToRootTab.wrappedValue) { _, newValue in
      if newValue == .timeline {
        if routerPath.path.isEmpty {
          scrollToTopSignal += 1
        } else {
          routerPath.path = []
        }
      }
    }
    .onChange(of: client.id) {
      routerPath.path = []
    }
    .onChange(of: timeline) { _, newValue in
      if client.isAuth, canFilterTimeline {
        lastTimelineFilter = newValue
      }
      switch newValue {
      case let .tagGroup(title, _, _):
        if let group = tagGroups.first(where: { $0.title == title }) {
          selectedTagGroup = group
        }
      default:
        selectedTagGroup = nil
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .refreshTimeline)) { _ in
      timeline = .latest
    }
    .onReceive(NotificationCenter.default.publisher(for: .trendingTimeline)) { _ in
      timeline = .trending
    }
    .onReceive(NotificationCenter.default.publisher(for: .localTimeline)) { _ in
      timeline = .local
    }
    .onReceive(NotificationCenter.default.publisher(for: .federatedTimeline)) { _ in
      timeline = .federated
    }
    .onReceive(NotificationCenter.default.publisher(for: .homeTimeline)) { _ in
      timeline = .home
    }
    .withSafariRouter()
    .environment(routerPath)
  }

  @ViewBuilder
  private var timelineFilterButton: some View {
    headerGroup
    timelineFiltersButtons
    if client.isAuth {
      listsFiltersButons
      tagsFiltersButtons
    }
    localTimelinesFiltersButtons
    tagGroupsFiltersButtons
    Divider()
    contentFilterButton
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
      ToolbarTab(routerPath: $routerPath)
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

  @ViewBuilder
  private var headerGroup: some View {
    ControlGroup {
      if timeline.supportNewestPagination {
        Button {
          timeline = .latest
        } label: {
          Label(TimelineFilter.latest.localizedTitle(), systemImage: TimelineFilter.latest.iconName())
        }
      }
      if timeline == .home {
        Button {
          timeline = .resume
        } label: {
          VStack {
            Label(TimelineFilter.resume.localizedTitle(),
                  systemImage: TimelineFilter.resume.iconName())
          }
        }
      }
      pinButton
    }
  }

  @ViewBuilder
  private var pinButton: some View {
    let index = pinnedFilters.firstIndex(where: { $0.id == timeline.id })
    Button {
      withAnimation {
        if let index {
          pinnedFilters.remove(at: index)
        } else {
          pinnedFilters.append(timeline)
        }
      }
    } label: {
      if index != nil {
        Label("status.action.unpin", systemImage: "pin.slash")
      } else {
        Label("status.action.pin", systemImage: "pin")
      }
    }
  }

  private var timelineFiltersButtons: some View {
    ForEach(TimelineFilter.availableTimeline(client: client), id: \.self) { timeline in
      Button {
        self.timeline = timeline
      } label: {
        Label(timeline.localizedTitle(), systemImage: timeline.iconName())
      }
    }
  }

  @ViewBuilder
  private var listsFiltersButons: some View {
    Menu("timeline.filter.lists") {
      Button {
        routerPath.presentedSheet = .listCreate
      } label: {
        Label("account.list.create", systemImage: "plus")
      }
      ForEach(currentAccount.sortedLists) { list in
        Button {
          timeline = .list(list: list)
        } label: {
          Label(list.title, systemImage: "list.bullet")
        }
      }
    }
  }

  @ViewBuilder
  private var tagsFiltersButtons: some View {
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
  }

  private var localTimelinesFiltersButtons: some View {
    Menu("timeline.filter.local") {
      ForEach(localTimelines) { remoteLocal in
        Button {
          timeline = .remoteLocal(server: remoteLocal.instance, filter: .local)
        } label: {
          VStack {
            Label(remoteLocal.instance, systemImage: "dot.radiowaves.right")
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

  private var tagGroupsFiltersButtons: some View {
    Menu("timeline.filter.tag-groups") {
      ForEach(tagGroups) { group in
        Button {
          timeline = .tagGroup(title: group.title, tags: group.tags, symbolName: group.symbolName)
        } label: {
          VStack {
            let icon = group.symbolName.isEmpty ? "number" : group.symbolName
            Label(group.title, systemImage: icon)
          }
        }
      }

      Button {
        routerPath.presentedSheet = .addTagGroup
      } label: {
        Label("timeline.filter.add-tag-groups", systemImage: "plus")
      }
    }
  }

  private var contentFilterButton: some View {
    Button(action: {
      routerPath.presentedSheet = .timelineContentFilter
    }, label: {
      Label("timeline.content-filter.title", systemSymbol: .line3HorizontalDecrease)
    })
  }

  private func resetTimelineFilter() {
    if client.isAuth, canFilterTimeline {
      timeline = lastTimelineFilter
    } else if !client.isAuth {
      timeline = .trending
    }
  }
}
