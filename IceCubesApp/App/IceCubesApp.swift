import SwiftUI
import Timeline
import Network
import KeychainSwift
import Env
import DesignSystem
import QuickLook
import RevenueCat

@main
struct IceCubesApp: App {
  public static let defaultServer = "mastodon.social"
    
  @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
  
  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var appAccountsManager = AppAccountsManager.shared
  @StateObject private var currentInstance = CurrentInstance()
  @StateObject private var currentAccount = CurrentAccount()
  @StateObject private var userPreferences = UserPreferences()
  @StateObject private var watcher = StreamWatcher()
  @StateObject private var quickLook = QuickLook()
  @StateObject private var theme = Theme()
  
  @State private var selectedTab: Tab = .timeline
  @State private var selectSidebarItem: Tab? = .timeline
  @State private var popToRootTab: Tab = .other
  
  private var availableTabs: [Tab] {
    appAccountsManager.currentClient.isAuth ? Tab.loggedInTabs() : Tab.loggedOutTab()
  }
  
  var body: some Scene {
    WindowGroup {
      appView
      .applyTheme(theme)
      .onAppear {
        setNewClientsInEnv(client: appAccountsManager.currentClient)
        setupRevenueCat()
        refreshPushSubs()
      }
      .environmentObject(appAccountsManager)
      .environmentObject(appAccountsManager.currentClient)
      .environmentObject(quickLook)
      .environmentObject(currentAccount)
      .environmentObject(currentInstance)
      .environmentObject(userPreferences)
      .environmentObject(theme)
      .environmentObject(watcher)
      .environmentObject(PushNotifications.shared)
      .quickLookPreview($quickLook.url, in: quickLook.urls)
    }
    .onChange(of: scenePhase) { scenePhase in
      handleScenePhase(scenePhase: scenePhase)
    }
    .onChange(of: appAccountsManager.currentClient) { newClient in
      setNewClientsInEnv(client: newClient)
      if newClient.isAuth {
        watcher.watch(streams: [.user, .direct])
      }
    }
  }
  
  @ViewBuilder
  private var appView: some View {
    if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac {
      splitView
    } else {
      tabBarView
    }
  }
  
  private func badgeFor(tab: Tab) -> Int {
    if tab == .notifications && selectedTab != tab {
      return watcher.unreadNotificationsCount
    } else if tab == .messages && selectedTab != tab {
      return watcher.unreadMessagesCount
    }
    return 0
  }
  
  private var tabBarView: some View {
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
      ForEach(availableTabs) { tab in
        tab.makeContentView(popToRootTab: $popToRootTab)
          .tabItem {
            tab.label
          }
          .tag(tab)
          .badge(badgeFor(tab: tab))
          .toolbarBackground(theme.primaryBackgroundColor.opacity(0.50), for: .tabBar)
      }
    }
  }
  
  private var splitView: some View {
    NavigationSplitView {
      List(availableTabs, selection: $selectSidebarItem) { tab in
        NavigationLink(value: tab) {
          tab.label
        }
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .navigationSplitViewColumnWidth(200)
    } detail: {
      selectSidebarItem?.makeContentView(popToRootTab: $popToRootTab)
    }
  }
  
  private func setNewClientsInEnv(client: Client) {
    currentAccount.setClient(client: client)
    currentInstance.setClient(client: client)
    watcher.setClient(client: client)
  }
  
  private func handleScenePhase(scenePhase: ScenePhase) {
    switch scenePhase {
    case .background:
      watcher.stopWatching()
    case .active:
      watcher.watch(streams: [.user, .direct])
    case .inactive:
      break
    default:
      break
    }
  }
  
  private func setupRevenueCat() {
    Purchases.logLevel = .error
    Purchases.configure(withAPIKey: "appl_JXmiRckOzXXTsHKitQiicXCvMQi")
  }
  
  private func refreshPushSubs() {
    PushNotifications.shared.requestPushNotifications()
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    return true
  }
  
  func application(_ application: UIApplication,
                   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    PushNotifications.shared.pushToken = deviceToken
    Task {
      await PushNotifications.shared.fetchSubscriptions(accounts: AppAccountsManager.shared.pushAccounts)
      await PushNotifications.shared.updateSubscriptions(accounts: AppAccountsManager.shared.pushAccounts)
    }
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print(error)
  }
}
