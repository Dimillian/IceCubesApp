import SwiftUI
import Timeline
import Env
import Network
import Combine

struct TimelineTab: View {
  @EnvironmentObject private var client: Client
  @StateObject private var routeurPath = RouterPath()
  @Binding var popToRootTab: IceCubesApp.Tab
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      TimelineView()
        .withAppRouteur()
        .withSheetDestinations(sheetDestinations: $routeurPath.presentedSheet)
        .toolbar {
          if client.isAuth {
            ToolbarItem(placement: .navigationBarLeading) {
              Button {
                routeurPath.presentedSheet = .statusEditor(replyToStatus: nil)
              } label: {
                Image(systemName: "square.and.pencil")
              }
            }
          }
        }
    }
    .environmentObject(routeurPath)
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .timeline {
        routeurPath.path = []
      }
    }
  }
}
