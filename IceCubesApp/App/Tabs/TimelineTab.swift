import SwiftUI
import Timeline
import Routeur
import Network

struct TimelineTab: View {
  @StateObject private var routeurPath = RouterPath()
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      TimelineView()
        .withAppRouteur()
        .withSheetDestinations(sheetDestinations: $routeurPath.presentedSheet)
    }
    .environmentObject(routeurPath)
  }
}
