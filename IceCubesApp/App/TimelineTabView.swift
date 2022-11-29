import SwiftUI
import Timeline
import Routeur

struct TimelineTabView: View {
  let tab: String
  @StateObject private var routeurPath = RouterPath()
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      TimelineView(client: .init(server: tab))
        .withAppRouteur()
    }
    .environmentObject(routeurPath)
  }
}
