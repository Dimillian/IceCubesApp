import AppAccount
import Combine
import DesignSystem
import Env
import Models
import NetworkClient
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
  @Environment(MastodonClient.self) private var client
  @State private var routerPath = RouterPath()

  @State private var didAppear: Bool = false
  @State private var selectedTagGroup: TagGroup?

  @Binding var timeline: TimelineFilter
  @Binding var pinnedFilters: [TimelineFilter]

  @AppStorage("last_timeline_filter") var lastTimelineFilter: TimelineFilter = .home

  @Query(sort: \LocalTimeline.creationDate, order: .reverse) var localTimelines: [LocalTimeline]
  @Query(sort: \TagGroup.creationDate, order: .reverse) var tagGroups: [TagGroup]

  private let canFilterTimeline: Bool

  init(
    canFilterTimeline: Bool = false, timeline: Binding<TimelineFilter>,
    pinedFilters: Binding<[TimelineFilter]> = .constant([])
  ) {
    self.canFilterTimeline = canFilterTimeline
    _timeline = timeline
    _pinnedFilters = pinedFilters
  }

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      TimelineView(
        timeline: $timeline,
        pinnedFilters: $pinnedFilters,
        selectedTagGroup: $selectedTagGroup,
        canFilterTimeline: canFilterTimeline
      )
      .withAppRouter()
      .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
      .toolbar {
        toolbarView
      }
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
      if !client.isAuth {
        routerPath.presentedSheet = .addAccount
      }
    }
    .task {
      await currentAccount.fetchLists()
    }
    .onChange(of: client.isAuth) {
      resetTimelineFilter()
    }
    .onChange(of: currentAccount.account?.id) {
      resetTimelineFilter()
    }
    .onChange(of: client.id) {
      routerPath.path = []
    }
    .onChange(of: timeline) { _, newValue in
      if client.isAuth, canFilterTimeline {
        lastTimelineFilter = newValue
      }
      switch newValue {
      case .tagGroup(let title, _, _):
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
          .tint(.label)
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
    case .list(let list):
      if #available(iOS 26.0, *) {
        ToolbarSpacer(placement: .topBarTrailing)
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          routerPath.presentedSheet = .listEdit(list: list)
        } label: {
          Image(systemName: "list.bullet")
            .foregroundStyle(theme.labelColor)
        }
      }
    case .remoteLocal(let server, _):
      if #available(iOS 26.0, *) {
        ToolbarSpacer(placement: .topBarTrailing)
      }
      ToolbarItem(placement: .topBarTrailing) {
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
            .foregroundStyle(theme.labelColor)
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
          Label(
            TimelineFilter.latest.localizedTitle(), systemImage: TimelineFilter.latest.iconName())
        }
      }
      if timeline == .home {
        Button {
          timeline = .resume
        } label: {
          VStack {
            Label(
              TimelineFilter.resume.localizedTitle(),
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
          let timeline = pinnedFilters.remove(at: index)
          Telemetry.signal("timeline.pin.removed", parameters: ["timeline": timeline.rawValue])
        } else {
          pinnedFilters.append(timeline)
          Telemetry.signal("timeline.pin.added", parameters: ["timeline": timeline.rawValue])
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
    Menu {
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
    } label: {
      Label("timeline.filter.lists", systemImage: "list.bullet")
    }
  }

  @ViewBuilder
  private var tagsFiltersButtons: some View {
    if !currentAccount.tags.isEmpty {
      Menu {
        ForEach(currentAccount.sortedTags) { tag in
          Button {
            timeline = .hashtag(tag: tag.name, accountId: nil)
          } label: {
            Label("#\(tag.name)", systemImage: "number")
          }
        }
      } label: {
        Label("timeline.filter.tags", systemImage: "tag")
      }
    }
  }

  private var localTimelinesFiltersButtons: some View {
    Menu {
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
    } label: {
      Label("timeline.filter.local", systemImage: "dot.radiowaves.right")
    }
  }

  private var tagGroupsFiltersButtons: some View {
    Menu {
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
    } label: {
      Label("timeline.filter.tag-groups", systemImage: "number")
    }
  }

  private var contentFilterButton: some View {
    Button(
      action: {
        routerPath.presentedSheet = .timelineContentFilter
      },
      label: {
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
