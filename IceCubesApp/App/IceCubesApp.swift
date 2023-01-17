import Account
import AppAccount
import AVFoundation
import DesignSystem
import Env
import KeychainSwift
import Network
import RevenueCat
import SwiftUI
import Timeline

@main
struct IceCubesApp: App {
  @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

  @Environment(\.scenePhase) private var scenePhase
  @StateObject private var appAccountsManager = AppAccountsManager.shared
  @StateObject private var currentInstance = CurrentInstance.shared
  @StateObject private var currentAccount = CurrentAccount.shared
  @StateObject private var userPreferences = UserPreferences.shared
  @StateObject private var watcher = StreamWatcher()
  @StateObject private var quickLook = QuickLook()
  @StateObject private var theme = Theme.shared
  @StateObject private var sidebarRouterPath = RouterPath()

  @State private var selectedTab: Tab = .timeline
  @State private var selectSidebarItem: Tab? = .timeline
  @State private var popToRootTab: Tab = .other
  @State private var sideBarLoadedTabs: Set<Tab> = Set()
  
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
        .environmentObject(PushNotificationsService.shared)
        .sheet(item: $quickLook.url, content: { url in
          QuickLookPreview(selectedURL: url, urls: quickLook.urls)
            .edgesIgnoringSafeArea(.bottom)
        })
    }
    .commands {
      CommandGroup(replacing: CommandGroupPlacement.newItem) {
        Button("New post") {
          sidebarRouterPath.presentedSheet = .newStatusEditor(visibility: userPreferences.serverPreferences?.postVisibility ?? .pub)
        }
      }
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
      sidebarView
    } else {
      tabBarView
    }
  }

  private func badgeFor(tab: Tab) -> Int {
    if tab == .notifications && selectedTab != tab {
      return watcher.unreadNotificationsCount + userPreferences.pushNotificationsCount
    }
    return 0
  }

  private var sidebarView: some View {
    SideBarView(selectedTab: $selectedTab,
                popToRootTab: $popToRootTab,
                tabs: availableTabs,
                routerPath: sidebarRouterPath) {
      ZStack {
        if selectedTab == .profile {
          ProfileTab(popToRootTab: $popToRootTab)
        }
        ForEach(availableTabs) { tab in
          if tab == selectedTab || sideBarLoadedTabs.contains(tab) {
            tab
              .makeContentView(popToRootTab: $popToRootTab)
              .opacity(tab == selectedTab ? 1 : 0)
              .id(tab)
              .onAppear {
                sideBarLoadedTabs.insert(tab)
              }
          } else {
            EmptyView()
          }
        }
      }
    }
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

  private func setNewClientsInEnv(client: Client) {
    currentAccount.setClient(client: client)
    currentInstance.setClient(client: client)
    userPreferences.setClient(client: client)
    watcher.setClient(client: client)
  }

  private func handleScenePhase(scenePhase: ScenePhase) {
    switch scenePhase {
    case .background:
      watcher.stopWatching()
    case .active:
      watcher.watch(streams: [.user, .direct])
      UIApplication.shared.applicationIconBadgeNumber = 0
      Task {
        await userPreferences.refreshServerPreferences()
      }
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
    PushNotificationsService.shared.requestPushNotifications()
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_: UIApplication,
                   didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool
  {
    try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
    return true
  }

  func application(_: UIApplication,
                   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
  {
    PushNotificationsService.shared.pushToken = deviceToken
    #if !DEBUG
      Task {
        await PushNotificationsService.shared.fetchSubscriptions(accounts: AppAccountsManager.shared.pushAccounts)
        await PushNotificationsService.shared.updateSubscriptions(accounts: AppAccountsManager.shared.pushAccounts)
      }
    #endif
  }

  func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {}
  
}
