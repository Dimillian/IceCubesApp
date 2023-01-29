import Account
import AppAccount
import DesignSystem
import Env
import Foundation
import Models
import Network
import SwiftUI
import Timeline

struct SettingsTabs: View {
  @Environment(\.dismiss) private var dismiss

  @EnvironmentObject private var pushNotifications: PushNotificationsService
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentInstance: CurrentInstance
  @EnvironmentObject private var appAccountsManager: AppAccountsManager
  @EnvironmentObject private var theme: Theme

  @StateObject private var routerPath = RouterPath()

  @State private var addAccountSheetPresented = false

  @Binding var popToRootTab: Tab

  var body: some View {
    NavigationStack(path: $routerPath.path) {
      Form {
        appSection
        accountsSection
        generalSection
        otherSections
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .navigationTitle(Text("settings.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(theme.primaryBackgroundColor.opacity(0.50), for: .navigationBar)
      .toolbar {
        if UIDevice.current.userInterfaceIdiom == .phone {
          ToolbarItem {
            Button("action.done") {
              dismiss()
            }
          }
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
    .environmentObject(routerPath)
    .onChange(of: $popToRootTab.wrappedValue) { popToRootTab in
      if popToRootTab == .notifications {
        routerPath.path = []
      }
    }
  }

  private var accountsSection: some View {
    Section("settings.section.accounts") {
      ForEach(appAccountsManager.availableAccounts) { account in
        AppAccountView(viewModel: .init(appAccount: account))
      }
      .onDelete { indexSet in
        if let index = indexSet.first {
          let account = appAccountsManager.availableAccounts[index]
          if let token = account.oauthToken,
             let sub = pushNotifications.subscriptions.first(where: { $0.account.token == token })
          {
            Task {
              await sub.deleteSubscription()
              appAccountsManager.delete(account: account)
            }
          }
        }
      }
      addAccountButton
    }
    .listRowBackground(theme.primaryBackgroundColor)
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
      NavigationLink(destination: remoteLocalTimelinesView) {
        Label("settings.general.remote-timelines", systemImage: "dot.radiowaves.right")
      }
      NavigationLink(destination: ContentSettingsView()) {
        Label("settings.general.content", systemImage: "rectangle.fill.on.rectangle.fill")
      }
      Link(destination: URL(string: UIApplication.openSettingsURLString)!) {
        Label("settings.system", systemImage: "gear")
      }
      .tint(theme.labelColor)
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }

  private var otherSections: some View {
    Section("settings.section.other") {
      if !ProcessInfo.processInfo.isiOSAppOnMac {
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
      }
      Toggle(isOn: $preferences.isOpenAIEnabled) {
        Label("settings.other.hide-openai", systemImage: "faxmachine")
      }
      Toggle(isOn: $preferences.isSocialKeyboardEnabled) {
        Label("settings.other.social-keyboard", systemImage: "keyboard")
      }
      Toggle(isOn: $preferences.autoPlayVideo) {
        Label("settings.other.autoplay-video", systemImage: "play.square.stack")
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }

  private var appSection: some View {
    Section {
      if !ProcessInfo.processInfo.isiOSAppOnMac {
        NavigationLink(destination: IconSelectorView()) {
          Label {
            Text("settings.app.icon")
          } icon: {
            if let icon = IconSelectorView.Icon(string: UIApplication.shared.alternateIconName ?? "AppIcon") {
              Image(uiImage: .init(named: icon.iconName)!)
                .resizable()
                .frame(width: 25, height: 25)
                .cornerRadius(4)
            }
          }
        }
      }

      Link(destination: URL(string: "https://github.com/Dimillian/IceCubesApp")!) {
        Label("settings.app.source", systemImage: "link")
      }
      .tint(theme.labelColor)

      NavigationLink(destination: SupportAppView()) {
        Label("settings.app.support", systemImage: "wand.and.stars")
      }

      if let reviewURL = URL(string: "https://apps.apple.com/app/id\(AppInfo.appStoreAppId)?action=write-review") {
        Link(destination: reviewURL) {
          Label("settings.rate", systemImage: "link")
        }
        .tint(theme.labelColor)
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

  private var remoteLocalTimelinesView: some View {
    Form {
      ForEach(preferences.remoteLocalTimelines, id: \.self) { server in
        Text(server)
      }.onDelete { indexes in
        if let index = indexes.first {
          _ = preferences.remoteLocalTimelines.remove(at: index)
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
  }
}
