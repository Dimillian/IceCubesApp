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
  @StateObject private var pushNotificationsService = PushNotificationsService.shared
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
        .environmentObject(pushNotificationsService)
        .fullScreenCover(item: $quickLook.url, content: { url in
          QuickLookPreview(selectedURL: url, urls: quickLook.urls)
            .edgesIgnoringSafeArea(.bottom)
            .background(TransparentBackground())
        })
        .onChange(of: pushNotificationsService.handledNotification) { notification in
          if notification != nil {
            pushNotificationsService.handledNotification = nil
            if appAccountsManager.currentAccount.oauthToken?.accessToken != notification?.account.token.accessToken,
               let account = appAccountsManager.availableAccounts.first(where:
                  { $0.oauthToken?.accessToken == notification?.account.token.accessToken })  {
              appAccountsManager.currentAccount = account
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                selectedTab = .notifications
                pushNotificationsService.handledNotification = notification
              }
            } else {
              selectedTab = .notifications
            }
          }
        }
    }
    .commands {
      appMenu
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
      GeometryReader { proxy in
        HStack(spacing: 0) {
          ZStack {
            if selectedTab == .profile {
              ProfileTab(popToRootTab: $popToRootTab)
            }
            ForEach(availableTabs) { tab in
              if tab == selectedTab || sideBarLoadedTabs.contains(tab) {
                tab
                  .makeContentView(popToRootTab: $popToRootTab)
                  .opacity(tab == selectedTab ? 1 : 0)
                  .transition(.opacity)
                  .id("\(tab)\(appAccountsManager.currentAccount.id)")
                  .onAppear {
                    sideBarLoadedTabs.insert(tab)
                  }
              } else {
                EmptyView()
              }
            }
          }
          if proxy.frame(in: .global).width > (.maxColumnWidth + .secondaryColumnWidth),
             appAccountsManager.currentClient.isAuth,
             userPreferences.showiPadSecondaryColumn
          {
            Divider().edgesIgnoringSafeArea(.all)
            NotificationsTab(popToRootTab: $popToRootTab, lockedType: nil)
              .environment(\.isSecondaryColumn, true)
              .frame(maxWidth: 360)
          }
        }
      }
    }.onChange(of: $appAccountsManager.currentAccount.id) { _ in
      sideBarLoadedTabs.removeAll()
    }
  }

  private var tabBarView: some View {
    TabView(selection: .init(get: {
      selectedTab
    }, set: { newTab in
      var transaction = Transaction()
      transaction.disablesAnimations = true
      withTransaction(transaction) {
        if newTab == selectedTab {
          /// Stupid hack to trigger onChange binding in tab views.
          popToRootTab = .other
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            popToRootTab = selectedTab
          }
        }
        selectedTab = newTab
      }
      HapticManager.shared.fireHaptic(of: .tabSelection)
    })) {
      ForEach(availableTabs) { tab in
        tab.makeContentView(popToRootTab: $popToRootTab)
          .tabItem {
            if userPreferences.showiPhoneTabLabel {
              tab.label
                .labelStyle(TitleAndIconLabelStyle())
            } else {
              tab.label
                .labelStyle(IconOnlyLabelStyle())
            }
          }
          .tag(tab)
          .badge(badgeFor(tab: tab))
          .toolbarBackground(theme.primaryBackgroundColor.opacity(0.50), for: .tabBar)
      }
    }
    .id(appAccountsManager.currentClient.id)
  }

  private func setNewClientsInEnv(client: Client) {
    currentAccount.setClient(client: client)
    currentInstance.setClient(client: client)
    userPreferences.setClient(client: client)
    Task {
      await currentInstance.fetchCurrentInstance()
      watcher.setClient(client: client, instanceStreamingURL: currentInstance.instance?.urls?.streamingApi)
      watcher.watch(streams: [.user, .direct])
    }
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

  @CommandsBuilder
  private var appMenu: some Commands {
    CommandGroup(replacing: .newItem) {
      Button("menu.new-post") {
        sidebarRouterPath.presentedSheet = .newStatusEditor(visibility: userPreferences.postVisibility)
      }
    }
    CommandGroup(replacing: .textFormatting) {
      Menu("menu.font") {
        Button("menu.font.bigger") {
          if userPreferences.fontSizeScale < 1.5 {
            userPreferences.fontSizeScale += 0.1
          }
        }
        Button("menu.font.smaller") {
          if userPreferences.fontSizeScale > 0.5 {
            userPreferences.fontSizeScale -= 0.1
          }
        }
      }
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  let themeObserver = ThemeObserverViewController(nibName: nil, bundle: nil)

  func application(_: UIApplication,
                   didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool
  {
    try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
    PushNotificationsService.shared.setAccounts(accounts: AppAccountsManager.shared.pushAccounts)
    return true
  }

  func application(_: UIApplication,
                   didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
  {
    PushNotificationsService.shared.pushToken = deviceToken
    Task {
      PushNotificationsService.shared.setAccounts(accounts: AppAccountsManager.shared.pushAccounts)
      await PushNotificationsService.shared.updateSubscriptions(forceCreate: false)
    }
  }

  func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {}

  func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
    let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    if connectingSceneSession.role == .windowApplication {
      configuration.delegateClass = SceneDelegate.self
    }
    return configuration
  }
}

class ThemeObserverViewController: UIViewController {
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    print(traitCollection.userInterfaceStyle.rawValue)
  }
}
