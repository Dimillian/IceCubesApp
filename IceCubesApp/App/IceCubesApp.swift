import SwiftUI
import Timeline
import Network
import KeychainSwift

@main
struct IceCubesApp: App {
  public static let defaultServer = "mastodon.social"
  
  @StateObject private var appAccountsManager = AppAccountsManager()
  
  var body: some Scene {
    WindowGroup {
      TabView {
        TimelineTab()
          .tabItem {
            Label("Home", systemImage: "globe")
          }
        NotificationsTab()
          .tabItem {
            Label("Notifications", systemImage: "bell")
          }
        SettingsTabs()
          .tabItem {
            Label("Settings", systemImage: "gear")
          }
      }
      .environmentObject(appAccountsManager)
      .environmentObject(appAccountsManager.currentClient)
    }
  }
}
