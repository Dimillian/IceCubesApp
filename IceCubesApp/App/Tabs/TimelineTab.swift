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
  @State private var scrollToTopSignal: Int = 0
  @State private var isAddAccountSheetDisplayed = false
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      TimelineView(timeline: $timeline, scrollToTopSignal: $scrollToTopSignal)
        .withAppRouteur()
        .withSheetDestinations(sheetDestinations: $routeurPath.presentedSheet)
        .toolbar {
          if client.isAuth {
            statusEditorToolbarItem(routeurPath: routeurPath)
            ToolbarItem(placement: .navigationBarLeading) {
              timelineFilterButton
            }
          } else {
            ToolbarItem(placement: .navigationBarTrailing) {
              addAccountButton
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
        if routeurPath.path.isEmpty {
          scrollToTopSignal += 1
        } else {
          routeurPath.path = []
        }
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
  
  private var addAccountButton: some View {
    Button {
      isAddAccountSheetDisplayed = true
    } label: {
      Image(systemName: "person.badge.plus")
    }
    .sheet(isPresented: $isAddAccountSheetDisplayed) {
      AddAccountView()
    }
  }
}
