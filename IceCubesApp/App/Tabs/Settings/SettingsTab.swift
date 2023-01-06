import SwiftUI
import Timeline
import Env
import Network
import Account
import Models
import DesignSystem

struct SettingsTabs: View {
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentInstance: CurrentInstance
  @EnvironmentObject private var appAccountsManager: AppAccountsManager
  @EnvironmentObject private var theme: Theme
  
  @StateObject private var routeurPath = RouterPath()
  
  @State private var addAccountSheetPresented = false
  
  var body: some View {
    NavigationStack(path: $routeurPath.path) {
      Form {
        appSection
        accountsSection
        generalSection
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .navigationTitle(Text("Settings"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(theme.primaryBackgroundColor, for: .navigationBar)
      .withAppRouteur()
      .withSheetDestinations(sheetDestinations: $routeurPath.presentedSheet)
    }
    .onAppear {
      routeurPath.client = client
    }
    .task {
      if appAccountsManager.currentAccount.oauthToken != nil {
        await currentInstance.fetchCurrentInstance()
      }
    }
  }
  
  private var accountsSection: some View {
    Section("Accounts") {
      ForEach(appAccountsManager.availableAccounts) { account in
        HStack {
          AppAccountView(viewModel: .init(appAccount: account))
        }
        .onTapGesture {
          withAnimation {
            appAccountsManager.currentAccount = account
          }
        }
      }
      .onDelete { indexSet in
        if let index = indexSet.first {
          let account = appAccountsManager.availableAccounts[index]
          appAccountsManager.delete(account: account)
        }
      }
      addAccountButton
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }
  
  @ViewBuilder
  private var generalSection: some View {
    Section("General") {
      if let instanceData = currentInstance.instance {
        NavigationLink(destination: InstanceInfoView(instance: instanceData)) {
          Label("Instance Information", systemImage: "server.rack")
        }
      }
      NavigationLink(destination: DisplaySettingsView()) {
        Label("Display Settings", systemImage: "paintpalette")
      }
      NavigationLink(destination: remoteLocalTimelinesView) {
        Label("Remote Local Timelines", systemImage: "dot.radiowaves.right")
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }
  
  private var appSection: some View {
    Section("App") {
      NavigationLink(destination: IconSelectorView()) {
        Label {
          Text("App Icon")
        } icon: {
          if let icon = IconSelectorView.Icon(string: UIApplication.shared.alternateIconName ?? "AppIcon") {
            Image(uiImage: .init(named: icon.iconName)!)
              .resizable()
              .frame(width: 25, height: 25)
              .cornerRadius(4)
          }
        }
      }
      Link(destination: URL(string: "https://github.com/Dimillian/IceCubesApp")!) {
        Label("Source (Github link)", systemImage: "link")
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }
  
  private var addAccountButton: some View {
    Button {
      addAccountSheetPresented.toggle()
    } label: {
      Text("Add account")
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
        routeurPath.presentedSheet = .addRemoteLocalTimeline
      } label: {
        Label("Add a local timeline", systemImage: "badge.plus.radiowaves.right")
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .navigationTitle("Remote Local Timelines")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }
}
