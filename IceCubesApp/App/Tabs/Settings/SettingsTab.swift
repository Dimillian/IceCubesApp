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
  @Environment(\.modelContext) private var context

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

  @Query(sort: \LocalTimeline.creationDate, order: .reverse) var localTimelines: [LocalTimeline]
  @Query(sort: \TagGroup.creationDate, order: .reverse) var tagGroups: [TagGroup]

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
      .background(theme.secondaryBackgroundColor)
      .navigationTitle(Text("settings.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(theme.primaryBackgroundColor.opacity(0.50), for: .navigationBar)
      .toolbar {
        if UIDevice.current.userInterfaceIdiom == .phone || isModal {
          ToolbarItem {
            Button {
              dismiss()
            } label: {
              Text("action.done").bold()
            }
          }
        }
        if UIDevice.current.userInterfaceIdiom == .pad, !preferences.showiPadSecondaryColumn {
          SecondaryColumnToolbarItem()
        }
      }
      .withAppRouter()
      .withSheetDestinations(sheetDestinations: $routerPath.presentedSheet)
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
          AppAccountView(viewModel: .init(appAccount: account))
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
    .listRowBackground(theme.primaryBackgroundColor)
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
      NavigationLink(destination: remoteLocalTimelinesView) {
        Label("settings.general.remote-timelines", systemImage: "dot.radiowaves.right")
      }
      NavigationLink(destination: tagGroupsView) {
        Label("timeline.filter.tag-groups", systemImage: "number")
      }
      NavigationLink(destination: ContentSettingsView()) {
        Label("settings.general.content", systemImage: "rectangle.stack")
      }
      NavigationLink(destination: SwipeActionsSettingsView()) {
        Label("settings.general.swipeactions", systemImage: "hand.draw")
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
    .listRowBackground(theme.primaryBackgroundColor)
  }

  @ViewBuilder
  private var otherSections: some View {
    @Bindable var preferences = preferences
    Section("settings.section.other") {
      if !ProcessInfo.processInfo.isMacCatalystApp {
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
      }
      Toggle(isOn: $preferences.isOpenAIEnabled) {
        Label("settings.other.hide-openai", systemImage: "faxmachine")
      }
      Toggle(isOn: $preferences.isSocialKeyboardEnabled) {
        Label("settings.other.social-keyboard", systemImage: "keyboard")
      }
      Toggle(isOn: $preferences.soundEffectEnabled) {
        Label("settings.other.sound-effect", systemImage: "hifispeaker")
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }

  private var appSection: some View {
    Section {
      if !ProcessInfo.processInfo.isMacCatalystApp {
        NavigationLink(destination: IconSelectorView()) {
          Label {
            Text("settings.app.icon")
          } icon: {
            let icon = IconSelectorView.Icon(string: UIApplication.shared.alternateIconName ?? "AppIcon")
            Image(uiImage: .init(named: icon.iconName)!)
              .resizable()
              .frame(width: 25, height: 25)
              .cornerRadius(4)
          }
        }
      }

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
    .listRowBackground(theme.primaryBackgroundColor)
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

  private var tagGroupsView: some View {
    Form {
      ForEach(tagGroups) { group in
        Label(group.title, systemImage: group.symbolName)
          .onTapGesture {
            routerPath.presentedSheet = .editTagGroup(tagGroup: group, onSaved: nil)
          }
      }
      .onDelete { indexes in
        if let index = indexes.first {
          context.delete(tagGroups[index])
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)

      Button {
        routerPath.presentedSheet = .addTagGroup
      } label: {
        Label("timeline.filter.add-tag-groups", systemImage: "plus")
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .navigationTitle("timeline.filter.tag-groups")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
    .toolbar {
      EditButton()
    }
  }

  private var remoteLocalTimelinesView: some View {
    Form {
      ForEach(localTimelines) { timeline in
        Text(timeline.instance)
      }.onDelete { indexes in
        if let index = indexes.first {
          context.delete(localTimelines[index])
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
      Button {
        routerPath.presentedSheet = .addRemoteLocalTimeline
      } label: {
        Label("settings.timeline.add", systemImage: "badge.plus.radiowaves.right")
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .navigationTitle("settings.general.remote-timelines")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
    .toolbar {
      EditButton()
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
    .listRowBackground(theme.primaryBackgroundColor)
  }
}
