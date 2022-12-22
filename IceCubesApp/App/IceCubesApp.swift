import SwiftUI
import Timeline
import Network
import KeychainSwift
import Env

@main
struct IceCubesApp: App {
  public static let defaultServer = "mastodon.social"
  
  @StateObject private var appAccountsManager = AppAccountsManager()
  @StateObject private var currentAccount = CurrentAccount()
  @StateObject private var quickLook = QuickLook()
    
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
      .onChange(of: appAccountsManager.currentClient) { newClient in
        currentAccount.setClient(client: newClient)
      }
      .onAppear {
        currentAccount.setClient(client: appAccountsManager.currentClient)
      }
      .environmentObject(appAccountsManager)
      .environmentObject(appAccountsManager.currentClient)
      .environmentObject(quickLook)
      .environmentObject(currentAccount)
      .quickLookPreview($quickLook.url, in: quickLook.urls)
    }
  }
}
