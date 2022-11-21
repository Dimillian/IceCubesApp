import SwiftUI
import Timeline
import Network

@main
struct IceCubesAppApp: App {
  @StateObject private var client = Client(server: "mastodon.social")
  
  var body: some Scene {
    WindowGroup {
      TimelineView(kind: .pub)
        .environmentObject(client)
    }
  }
}
