import SwiftUI
import Timeline
import Env
import Network
import Account
import Models
import DesignSystem

struct SettingsTabs: View {
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentInstance: CurrentInstance
  @EnvironmentObject private var appAccountsManager: AppAccountsManager
  @EnvironmentObject private var theme: Theme
  
  @StateObject private var routeurPath = RouterPath()
  
  @State private var addAccountSheetPresented = false
  @State private var isThemeSelectorPresented = false
  
  var body: some View {
    NavigationStack {
      Form {
        appSection
        accountsSection
        themeSection
        instanceSection
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .navigationTitle(Text("Settings"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(theme.primaryBackgroundColor, for: .navigationBar)
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
  
  private var themeSection: some View {
    Section("Theme") {
      themeSelectorButton
      ColorPicker("Tint color", selection: $theme.tintColor)
      ColorPicker("Background color", selection: $theme.primaryBackgroundColor)
      ColorPicker("Secondary Background color", selection: $theme.secondaryBackgroundColor)
      Picker("Avatar position", selection: $theme.avatarPosition) {
        ForEach(Theme.AvatarPosition.allCases, id: \.rawValue) { position in
          Text(position.description).tag(position)
        }
      }
      Button {
        theme.selectedSet = .iceCubeDark
      } label: {
        Text("Restore default")
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }
  
  @ViewBuilder
  private var instanceSection: some View {
    if let instanceData = currentInstance.instance {
      InstanceInfoView(instance: instanceData)
    }
  }
  
  private var appSection: some View {
    Section("App") {
      NavigationLink(destination: IconSelectorView()) {
        Label {
          Text("Icon selector")
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
        Text("https://github.com/Dimillian/IceCubesApp")
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
  
  private var themeSelectorButton: some View {
    Button {
      isThemeSelectorPresented.toggle()
    } label: {
      HStack {
        Text("Select theme")
        Spacer()
        Text(theme.selectedSet.rawValue)
      }
    }
    .sheet(isPresented: $isThemeSelectorPresented) {
      ThemePreviewView()
    }
  }
  
  private var signOutButton: some View {
    Button {
      appAccountsManager.delete(account: appAccountsManager.currentAccount)
    } label: {
      Text("Sign out").foregroundColor(.red)
    }
  }
}
