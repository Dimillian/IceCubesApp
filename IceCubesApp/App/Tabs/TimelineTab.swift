import SwiftUI
import Timeline
import Env
import Network
import Combine

struct TimelineTab: View {
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var client: Client
  @StateObject private var routeurPath = RouterPath()
  @Binding var popToRootTab: Tab
  @State private var timeline: TimelineFilter = .home
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      TimelineView(timeline: $timeline)
        .withAppRouteur()
        .withSheetDestinations(sheetDestinations: $routeurPath.presentedSheet)
        .toolbar {
          if client.isAuth {
            statusEditorToolbarItem(routeurPath: routeurPath)
            ToolbarItem(placement: .navigationBarLeading) {
              timelineFilterButton
            }
          }
        }
        .id(currentAccount.account?.id)
    }
    .onAppear {
      routeurPath.client = client
      timeline = client.isAuth ? .home : .pub
    }
    .environmentObject(routeurPath)
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .timeline {
        routeurPath.path = []
      }
    }
  }
  
  
  private var timelineFilterButton: some View {
    Menu {
      ForEach(TimelineFilter.availableTimeline(), id: \.self) { timeline in
        Button {
          self.timeline = timeline
        } label: {
          Label(timeline.title(), systemImage: timeline.iconName() ?? "")
        }
      }
    } label: {
      Image(systemName: "line.3.horizontal.decrease.circle")
    }

  }
}
