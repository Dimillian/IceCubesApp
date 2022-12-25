import SwiftUI
import Timeline
import Network
import KeychainSwift
import Env
import DesignSystem

@main
struct IceCubesApp: App {
  enum Tab: Int {
    case timeline, notifications, explore, account, settings, other
  }
  
  public static let defaultServer = "mastodon.social"
    
  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var appAccountsManager = AppAccountsManager()
  @StateObject private var currentAccount = CurrentAccount()
  @StateObject private var watcher = StreamWatcher()
  @StateObject private var quickLook = QuickLook()
  @StateObject private var theme = Theme()
  
  @State private var selectedTab: Tab = .timeline
  @State private var popToRootTab: Tab = .other
  
  var body: some Scene {
    WindowGroup {
      TabView(selection: .init(get: {
        selectedTab
      }, set: { newTab in
        if newTab == selectedTab {
          /// Stupid hack to trigger onChange binding in tab views.
          popToRootTab = .other
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            popToRootTab = selectedTab
          }
        }
        selectedTab = newTab
      })) {
        TimelineTab(popToRootTab: $popToRootTab)
          .tabItem {
            Label("Timeline", systemImage: "rectangle.on.rectangle")
          }
          .tag(Tab.timeline)
        if appAccountsManager.currentClient.isAuth {
          NotificationsTab(popToRootTab: $popToRootTab)
            .tabItem {
              Label("Notifications", systemImage: "bell")
            }
            .badge(watcher.unreadNotificationsCount)
            .tag(Tab.notifications)
          ExploreTab(popToRootTab: $popToRootTab)
            .tabItem {
              Label("Explore", systemImage: "magnifyingglass")
            }
            .tag(Tab.explore)
          AccountTab(popToRootTab: $popToRootTab)
            .tabItem {
              Label("Profile", systemImage: "person.circle")
            }
            .tag(Tab.account)
        }
        SettingsTabs()
          .tabItem {
            Label("Settings", systemImage: "gear")
          }
          .tag(Tab.settings)
      }
      .tint(theme.tintColor)
      .onChange(of: appAccountsManager.currentClient) { newClient in
        currentAccount.setClient(client: newClient)
        watcher.setClient(client: newClient)
        if newClient.isAuth {
          watcher.watch(stream: .user)
        }
      }
      .onAppear {
        currentAccount.setClient(client: appAccountsManager.currentClient)
        watcher.setClient(client: appAccountsManager.currentClient)
      }
      .environmentObject(appAccountsManager)
      .environmentObject(appAccountsManager.currentClient)
      .environmentObject(quickLook)
      .environmentObject(currentAccount)
      .environmentObject(theme)
      .environmentObject(watcher)
      .quickLookPreview($quickLook.url, in: quickLook.urls)
    }
    .onChange(of: scenePhase, perform: { scenePhase in
      switch scenePhase {
      case .background:
        watcher.stopWatching()
      case .active:
        watcher.watch(stream: .user)
      case .inactive:
        break
      default:
        break
      }
    })
  }
}
