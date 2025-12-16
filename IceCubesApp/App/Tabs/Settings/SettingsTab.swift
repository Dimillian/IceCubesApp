import Account
import AppAccount
import DesignSystem
import Env
import Foundation
import Models
import NetworkClient
import Nuke
import SwiftData
import SwiftUI
import Timeline

@MainActor
struct SettingsTabs: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  @Environment(PushNotificationsService.self) private var pushNotifications
  @Environment(UserPreferences.self) private var preferences
  @Environment(MastodonClient.self) private var client
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(AppAccountsManager.self) private var appAccountsManager
  @Environment(Theme.self) private var theme

  @State private var routerPath = RouterPath()
  @State private var addAccountSheetPresented = false
  @State private var isEditingAccount = false
  @State private var cachedRemoved = false
  @State private var timelineCache = TimelineCache()

  let isModal: Bool

  @State private var startingPoint: SettingsStartingPoint? = nil

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      Form {
        appSection
        accountsSection
        generalSection
        otherSections
        cacheSection
      }
      .scrollContentBackground(.hidden)
      #if !os(visionOS)
        .background(theme.secondaryBackgroundColor)
      #endif
      .navigationTitle(Text("settings.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        if isModal {
          ToolbarItem {
            Button {
              dismiss()
            } label: {
              Text("action.done").bold()
            }
          }
        }
        if UIDevice.current.userInterfaceIdiom == .pad, !preferences.showiPadSecondaryColumn,
          !isModal
        {
          SecondaryColumnToolbarItem()
        }
      }
      .withAppRouter()
      .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
      .onAppear {
        startingPoint = RouterPath.settingsStartingPoint
        RouterPath.settingsStartingPoint = nil
      }
      .navigationDestination(item: $startingPoint) { targetView in
        switch targetView {
        case .display:
          DisplaySettingsView()
        case .haptic:
          HapticSettingsView()
        case .remoteTimelines:
          RemoteTimelinesSettingView()
        case .tagGroups:
          TagsGroupSettingView()
        case .recentTags:
          RecenTagsSettingView()
        case .content:
          ContentSettingsView()
        case .swipeActions:
          SwipeActionsSettingsView()
        case .tabAndSidebarEntries:
          EmptyView()
        case .translation:
          TranslationSettingsView()
        }
      }
    }
    .onAppear {
      routerPath.client = client
    }
    .task {
      if appAccountsManager.currentAccount.oauthToken != nil {
        await currentInstance.fetchCurrentInstance()
      }
    }
    .withSafariRouter()
    .environment(routerPath)
  }

  private var accountsSection: some View {
    Section("settings.section.accounts") {
      ForEach(appAccountsManager.availableAccounts) { account in
        HStack {
          if isEditingAccount {
            Button {
              Task {
                await logoutAccount(account: account)
              }
            } label: {
              Image(systemName: "trash")
                .renderingMode(.template)
                .tint(.red)
            }
          }
          AppAccountView(viewModel: .init(appAccount: account), isParentPresented: .constant(false))
        }
      }
      .onDelete { indexSet in
        if let index = indexSet.first {
          let account = appAccountsManager.availableAccounts[index]
          Task {
            await logoutAccount(account: account)
          }
        }
      }
      addAccountButton
      if !appAccountsManager.availableAccounts.isEmpty {
        editAccountButton
      }
    }
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  private func logoutAccount(account: AppAccount) async {
    if let token = account.oauthToken,
      let sub = pushNotifications.subscriptions.first(where: { $0.account.token == token })
    {
      let client = MastodonClient(server: account.server, oauthToken: token)
      await timelineCache.clearCache(for: client.id)
      await sub.deleteSubscription()
      appAccountsManager.delete(account: account)
      Telemetry.signal("account.removed")
    }
  }

  @ViewBuilder
  private var generalSection: some View {
    Section("settings.section.general") {
      if let instanceData = currentInstance.instance {
        NavigationLink(value: RouterDestination.instanceInfo(instance: instanceData)) {
          Label("settings.general.instance", systemImage: "server.rack")
        }
      }
      NavigationLink(destination: DisplaySettingsView()) {
        Label("settings.general.display", systemImage: "paintpalette")
      }
      if HapticManager.shared.supportsHaptics {
        NavigationLink(destination: HapticSettingsView()) {
          Label("settings.general.haptic", systemImage: "waveform.path")
        }
      }
      NavigationLink(destination: RemoteTimelinesSettingView()) {
        Label("settings.general.remote-timelines", systemImage: "dot.radiowaves.right")
      }
      NavigationLink(destination: TagsGroupSettingView()) {
        Label("timeline.filter.tag-groups", systemImage: "number")
      }
      NavigationLink(destination: RecenTagsSettingView()) {
        Label("settings.general.recent-tags", systemImage: "clock")
      }
      NavigationLink(destination: ContentSettingsView()) {
        Label("settings.general.content", systemImage: "rectangle.stack")
      }
      NavigationLink(destination: SwipeActionsSettingsView()) {
        Label("settings.general.swipeactions", systemImage: "hand.draw")
      }
      if UIDevice.current.userInterfaceIdiom == .phone || horizontalSizeClass == .compact {
        NavigationLink(destination: TabbarEntriesSettingsView()) {
          Label("settings.general.tabbarEntries", systemImage: "platter.filled.bottom.iphone")
        }
      }
      NavigationLink(destination: TranslationSettingsView()) {
        Label("settings.general.translate", systemImage: "captions.bubble")
      }
      #if !targetEnvironment(macCatalyst)
        Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
          Label("settings.system", systemImage: "gear")
        }
        .tint(theme.labelColor)
      #endif
    }
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  @ViewBuilder
  private var otherSections: some View {
    @Bindable var preferences = preferences
    Section {
      #if !targetEnvironment(macCatalyst)
        Picker(selection: $preferences.preferredBrowser) {
          ForEach(PreferredBrowser.allCases, id: \.rawValue) { browser in
            switch browser {
            case .inAppSafari:
              Text("settings.general.browser.in-app").tag(browser)
            case .safari:
              Text("settings.general.browser.system").tag(browser)
            }
          }
        } label: {
          Label("settings.general.browser", systemImage: "network")
        }
        Toggle(isOn: $preferences.inAppBrowserReaderView) {
          Label("settings.general.browser.in-app.readerview", systemImage: "doc.plaintext")
        }
        .disabled(preferences.preferredBrowser != PreferredBrowser.inAppSafari)
      #endif
      Toggle(isOn: $preferences.isSocialKeyboardEnabled) {
        Label("settings.other.social-keyboard", systemImage: "keyboard")
      }
      Toggle(isOn: $preferences.soundEffectEnabled) {
        Label("settings.other.sound-effect", systemImage: "hifispeaker")
      }
      Toggle(isOn: $preferences.streamHomeTimeline) {
        Label("Stream home timeline", systemImage: "antenna.radiowaves.left.and.right")
          .symbolVariant(preferences.streamHomeTimeline ? .none : .slash)
      }
      Toggle(isOn: $preferences.fullTimelineFetch) {
        Label("Full timeline fetch", systemImage: "arrow.triangle.2.circlepath")
          .symbolVariant(preferences.fullTimelineFetch ? .none : .slash)
      }
    } header: {
      Text("settings.section.other")
    }
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  private var appSection: some View {
    Section {
      #if !targetEnvironment(macCatalyst) && !os(visionOS)
        NavigationLink(destination: IconSelectorView()) {
          Label {
            Text("settings.app.icon")
          } icon: {
            let icon = IconSelectorView.Icon(
              string: UIApplication.shared.alternateIconName ?? "AppIcon")
            if let image: UIImage = .init(named: icon.previewImageName) {
              Image(uiImage: image)
                .resizable()
                .frame(width: 25, height: 25)
                .cornerRadius(4)
            } else {
              EmptyView()
            }
          }
        }
      #endif

      Link(destination: URL(string: "https://github.com/Dimillian/IceCubesApp")!) {
        Label("settings.app.source", systemImage: "link")
      }
      .accessibilityRemoveTraits(.isButton)
      .tint(theme.labelColor)

      NavigationLink(destination: SupportAppView()) {
        Label("settings.app.support", systemImage: "wand.and.stars")
      }

      if let reviewURL = URL(
        string: "https://apps.apple.com/app/id\(AppInfo.appStoreAppId)?action=write-review")
      {
        Link(destination: reviewURL) {
          Label("settings.rate", systemImage: "link")
        }
        .accessibilityRemoveTraits(.isButton)
        .tint(theme.labelColor)
      }

      NavigationLink {
        AboutView()
      } label: {
        Label("settings.app.about", systemImage: "info.circle")
      }

      NavigationLink {
        WishlistView()
      } label: {
        Label("Feature Requests", systemImage: "list.bullet.rectangle.portrait")
      }

    } header: {
      Text("settings.section.app")
    } footer: {
      if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
        Text("settings.section.app.footer \(appVersion)").frame(
          maxWidth: .infinity, alignment: .center)
      }
    }
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  private var addAccountButton: some View {
    Button {
      addAccountSheetPresented.toggle()
    } label: {
      Label("settings.account.add", systemImage: "person.badge.plus")
    }
    .sheet(isPresented: $addAccountSheetPresented) {
      AddAccountView()
    }
  }

  private var editAccountButton: some View {
    Button(role: .destructive) {
      withAnimation {
        isEditingAccount.toggle()
      }
    } label: {
      if isEditingAccount {
        Label("action.done", systemImage: "person.badge.minus")
          .foregroundStyle(.red)
      } else {
        Label("account.action.logout", systemImage: "person.badge.minus")
          .foregroundStyle(.red)
      }
    }
  }

  private var cacheSection: some View {
    Section {
      if cachedRemoved {
        Text("action.done")
          .transition(.move(edge: .leading))
      } else {
        Button("settings.cache-media.clear", role: .destructive) {
          ImagePipeline.shared.cache.removeAll()
          withAnimation {
            cachedRemoved = true
          }
        }
      }
    } header: {
      Text("settings.section.cache")
    } footer: {
      Text("Remove all cached images and videos")
    }
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }
}
