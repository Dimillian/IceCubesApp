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
        if appAccountsManager.currentClient.isAuth {
          NotificationsTab()
            .tabItem {
              Label("Notifications", systemImage: "bell")
            }
          AccountTab()
            .tabItem {
              Label("Profile", systemImage: "person.circle")
            }
        }
        SettingsTabs()
          .tabItem {
            Label("Settings", systemImage: "gear")
          }
      }
      .tint(.brand)
      .environmentObject(appAccountsManager)
      .environmentObject(appAccountsManager.currentClient)
    }
  }
}
