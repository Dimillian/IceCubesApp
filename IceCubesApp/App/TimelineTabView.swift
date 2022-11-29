import SwiftUI
import Timeline
import Routeur
import Network

struct TimelineTabView: View {
  let tab: String
  
  private let client: Client
  @StateObject private var routeurPath = RouterPath()
  
  init(tab: String) {
    self.tab = tab
    self.client = .init(server: tab)
  }
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      TimelineView()
        .withAppRouteur()
    }
    .environmentObject(routeurPath)
    .environmentObject(client)
  }
}
