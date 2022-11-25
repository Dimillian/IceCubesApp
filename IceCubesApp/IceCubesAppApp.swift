import SwiftUI
import Timeline
import Network

@main
struct IceCubesAppApp: App {
  @State private var tabs: [String] = ["mastodon.social"]
  @State private var isServerSelectDisplayed: Bool = false
  @State private var newServerURL: String = ""
  
  var body: some Scene {
    WindowGroup {
      TabView {
        ForEach(tabs, id: \.self) { tab in
          NavigationStack {
            TimelineView(client: .init(server: tab))
              .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                  Button {
                    isServerSelectDisplayed.toggle()
                  } label: {
                    Image(systemName: "globe")
                  }
                }
              }
              .alert("Connect to another server", isPresented: $isServerSelectDisplayed) {
                TextField(tab, text: $newServerURL)
                Button("Connect", action: {
                  tabs.append(newServerURL)
                  newServerURL = ""
                })
                Button("Cancel", role: .cancel, action: {})
              }
          }
          .tabItem {
            Label(tab, systemImage: "globe")
          }
        }
      }
    }
  }
}
