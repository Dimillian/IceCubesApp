import SwiftUI
import Timeline
import Env
import Network

struct TimelineTab: View {
  @StateObject private var routeurPath = RouterPath()
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      TimelineView()
        .withAppRouteur()
        .withSheetDestinations(sheetDestinations: $routeurPath.presentedSheet)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button {
              routeurPath.presentedSheet = .statusEditor(replyToStatus: nil)
            } label: {
              Image(systemName: "square.and.pencil")
            }

          }
        }
    }
    .environmentObject(routeurPath)
  }
}
