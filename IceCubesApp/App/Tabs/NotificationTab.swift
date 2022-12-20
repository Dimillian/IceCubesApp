import SwiftUI
import Timeline
import Routeur
import Network
import Notifications

struct NotificationsTab: View {
  @StateObject private var routeurPath = RouterPath()
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      NotificationsListView()
        .withAppRouteur()
        .withSheetDestinations(sheetDestinations: $routeurPath.presentedSheet)
    }
    .environmentObject(routeurPath)
  }
}
