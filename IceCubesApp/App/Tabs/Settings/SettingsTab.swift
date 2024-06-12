import Account
import AppAccount
import DesignSystem
import Env
import Foundation
import Models
import Network
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
  @Environment(Client.self) private var client
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(AppAccountsManager.self) private var appAccountsManager
  @Environment(Theme.self) private var theme

  @State private var routerPath = RouterPath()
  @State private var addAccountSheetPresented = false
  @State private var isEditingAccount = false
  @State private var cachedRemoved = false
  @State private var timelineCache = TimelineCache()

  @Binding var popToRootTab: Tab

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
        .toolbarBackground(theme.primaryBackgroundColor.opacity(0.30), for: .navigationBar)
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
          if UIDevice.current.userInterfaceIdiom == .pad, !preferences.showiPadSecondaryColumn, !isModal {
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
    .onChange(of: $popToRootTab.wrappedValue) { _, newValue in
      if newValue == .notifications {
        routerPath.path = []
      }
    }
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
      if !appAccountsManager.availableAccounts.isEmpty {
        editAccountButton
      }
      addAccountButton
    }
    #if !os(visionOS)
    .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  private func logoutAccount(account: AppAccount) async {
    if let token = account.oauthToken,
       let sub = pushNotifications.subscriptions.first(where: { $0.account.token == token })
    {
      let client = Client(server: account.server, oauthToken: token)
      await timelineCache.clearCache(for: client.id)
      await sub.deleteSubscription()
      appAccountsManager.delete(account: account)
    }
  }

  @ViewBuilder
  private var generalSection: some View {
    Section("settings.section.general") {
      if let instanceData = currentInstance.instance {
        NavigationLink(destination: InstanceInfoView(instance: instanceData)) {
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
      } else if UIDevice.current.userInterfaceIdiom == .pad || UIDevice.current.userInterfaceIdiom == .mac {
        NavigationLink(destination: SidebarEntriesSettingsView()) {
          Label("settings.general.sidebarEntries", systemImage: "sidebar.squares.leading")
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
      Toggle(isOn: $preferences.isOpenAIEnabled) {
        Label("settings.other.hide-openai", systemImage: "faxmachine")
      }
      Toggle(isOn: $preferences.isSocialKeyboardEnabled) {
        Label("settings.other.social-keyboard", systemImage: "keyboard")
      }
      Toggle(isOn: $preferences.soundEffectEnabled) {
        Label("settings.other.sound-effect", systemImage: "hifispeaker")
      }
      Toggle(isOn: $preferences.fastRefreshEnabled) {
        Label("settings.other.fast-refresh", systemImage: "arrow.clockwise")
      }
    } header: {
      Text("settings.section.other")
    } footer: {
      Text("settings.section.other.footer")
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
            let icon = IconSelectorView.Icon(string: UIApplication.shared.alternateIconName ?? "AppIcon")
            if let image: UIImage = .init(named: icon.appIconName) {
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

      if let reviewURL = URL(string: "https://apps.apple.com/app/id\(AppInfo.appStoreAppId)?action=write-review") {
        Link(destination: reviewURL) {
          Label("settings.rate", systemImage: "link")
        }
        .accessibilityRemoveTraits(.isButton)
        .tint(theme.labelColor)
      }

      NavigationLink(destination: AboutView()) {
        Label("settings.app.about", systemImage: "info.circle")
      }

    } header: {
      Text("settings.section.app")
    } footer: {
      if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
        Text("settings.section.app.footer \(appVersion)").frame(maxWidth: .infinity, alignment: .center)
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
      Text("settings.account.add")
    }
    .sheet(isPresented: $addAccountSheetPresented) {
      AddAccountView()
    }
  }

  private var editAccountButton: some View {
    Button(role: isEditingAccount ? .none : .destructive) {
      withAnimation {
        isEditingAccount.toggle()
      }
    } label: {
      if isEditingAccount {
        Text("action.done")
      } else {
        Text("account.action.logout")
      }
    }
  }

  private var cacheSection: some View {
    Section("settings.section.cache") {
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
    }
    #if !os(visionOS)
    .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }
}
