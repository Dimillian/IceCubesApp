import SwiftUI
import Timeline
import Network
import KeychainSwift
import Env
import DesignSystem

@main
struct IceCubesApp: App {
  public static let defaultServer = "mastodon.social"
    
  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var appAccountsManager = AppAccountsManager()
  @StateObject private var currenInstance = CurrentInstance()
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
        ForEach(appAccountsManager.currentClient.isAuth ? Tab.loggedInTabs() : Tab.loggedOutTab()) { tab in
          tab.makeContentView(popToRootTab: $popToRootTab)
            .tabItem {
              tab.label
            }
            .tag(tab)
            .badge(tab == .notifications ? watcher.unreadNotificationsCount : 0)
        }
      }
      .tint(theme.tintColor)
      .onChange(of: appAccountsManager.currentClient) { newClient in
        setNewClientsInEnv(client: newClient)
        if newClient.isAuth {
          watcher.watch(stream: .user)
        }
      }
      .onAppear {
        setNewClientsInEnv(client: appAccountsManager.currentClient)
      }
      .environmentObject(appAccountsManager)
      .environmentObject(appAccountsManager.currentClient)
      .environmentObject(quickLook)
      .environmentObject(currentAccount)
      .environmentObject(currenInstance)
      .environmentObject(theme)
      .environmentObject(watcher)
      .quickLookPreview($quickLook.url, in: quickLook.urls)
    }
    .onChange(of: scenePhase, perform: { scenePhase in
      handleScenePhase(scenePhase: scenePhase)
    })
  }
  
  private func setNewClientsInEnv(client: Client) {
    currentAccount.setClient(client: client)
    currenInstance.setClient(client: client)
    watcher.setClient(client: client)
  }
  
  private func handleScenePhase(scenePhase: ScenePhase) {
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
  }
}
