import AVFoundation
import Account
import AppAccount
import DesignSystem
import Env
import KeychainSwift
import MediaUI
import NetworkClient
import RevenueCat
import StatusKit
import SwiftUI
import Timeline
import WishKit

@main
struct IceCubesApp: App {
  @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

  @Environment(\.scenePhase) var scenePhase
  @Environment(\.openWindow) var openWindow

  @State var appAccountsManager = AppAccountsManager.shared
  @State var currentInstance = CurrentInstance.shared
  @State var currentAccount = CurrentAccount.shared
  @State var userPreferences = UserPreferences.shared
  @State var pushNotificationsService = PushNotificationsService.shared
  @State var appIntentService = AppIntentService.shared
  @State var watcher = StreamWatcher.shared
  @State var quickLook = QuickLook.shared
  @State var theme = Theme.shared

  @State var selectedTab: AppTab = .timeline
  @State var appRouterPath = RouterPath()

  @State var isSupporter: Bool = false
  
  @Namespace var namespace

  init() {
    #if DEBUG
      UserDefaults.standard.register(defaults: [
        "com.apple.SwiftUI.GraphReuseLogging": true, // Enable "GraphReuseLogging" by default. The log can be found via - subsystem: "com.apple.SwiftUI" category: "GraphReuse"
        "LogForEachSlowPath": true, // Enable "LogForEachSlowPath" by default. The log can be found via - subsystem: "com.apple.SwiftUI" category: "Invalid Configuration"
      ])
    #endif
  }

  var body: some Scene {
    appScene
    otherScenes
  }

  func setNewClientsInEnv(client: MastodonClient) {
    quickLook.namespace = namespace
    currentAccount.setClient(client: client)
    currentInstance.setClient(client: client)
    userPreferences.setClient(client: client)
    Task {
      await currentInstance.fetchCurrentInstance()
      watcher.setClient(
        client: client, instanceStreamingURL: currentInstance.instance?.urls?.streamingApi)
      watcher.watch(streams: [.user, .direct])
    }
  }

  func handleScenePhase(scenePhase: ScenePhase) {
    switch scenePhase {
    case .background:
      watcher.stopWatching()
    case .active:
      watcher.watch(streams: [.user, .direct])
      UNUserNotificationCenter.current().setBadgeCount(0)
      userPreferences.reloadNotificationsCount(
        tokens: appAccountsManager.availableAccounts.compactMap(\.oauthToken))
      Task {
        await userPreferences.refreshServerPreferences()
      }
    default:
      break
    }
  }

  func setupRevenueCat() {
    Purchases.logLevel = .error
    Purchases.configure(withAPIKey: "appl_JXmiRckOzXXTsHKitQiicXCvMQi")
    Purchases.shared.getCustomerInfo { info, _ in
      if info?.entitlements["Supporter"]?.isActive == true {
        isSupporter = true
      }
    }
  }

  func refreshPushSubs() {
    PushNotificationsService.shared.requestPushNotifications()
  }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _: UIApplication,
    didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
    try? AVAudioSession.sharedInstance().setActive(true)
    PushNotificationsService.shared.setAccounts(accounts: AppAccountsManager.shared.pushAccounts)
    Telemetry.setup()
    Telemetry.signal("app.launched")
    WishKit.configure(with: "AF21AE07-3BA9-4FE2-BFB1-59A3B3941730")
    return true
  }

  func application(
    _: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    PushNotificationsService.shared.pushToken = deviceToken
    Task {
      PushNotificationsService.shared.setAccounts(accounts: AppAccountsManager.shared.pushAccounts)
      await PushNotificationsService.shared.updateSubscriptions(forceCreate: false)
    }
  }

  func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {}

  func application(_: UIApplication, didReceiveRemoteNotification _: [AnyHashable: Any]) async
    -> UIBackgroundFetchResult
  {
    UserPreferences.shared.reloadNotificationsCount(
      tokens: AppAccountsManager.shared.availableAccounts.compactMap(\.oauthToken))
    return .noData
  }

  func application(
    _: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
    options _: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    if connectingSceneSession.role == .windowApplication {
      configuration.delegateClass = SceneDelegate.self
    }
    return configuration
  }

  override func buildMenu(with builder: UIMenuBuilder) {
    super.buildMenu(with: builder)
    builder.remove(menu: .document)
    builder.remove(menu: .toolbar)
  }
}
