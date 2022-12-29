import SwiftUI
import Timeline
import Env
import Network
import Account
import Models
import DesignSystem

struct SettingsTabs: View {
  @Environment(\.openURL) private var openURL
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var currentInstance: CurrentInstance
  @EnvironmentObject private var appAccountsManager: AppAccountsManager
  @EnvironmentObject private var theme: Theme
  
  @State private var signInInProgress = false
  @State private var signInServer = IceCubesApp.defaultServer
  
  var body: some View {
    NavigationStack {
      Form {
        appSection
        accountsSection
        themeSection
        instanceSection
      }
      .onOpenURL(perform: { url in
        Task {
          await continueSignIn(url: url)
        }
      })
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .navigationTitle(Text("Settings"))
      .navigationBarTitleDisplayMode(.inline)
    }
    .task {
      if appAccountsManager.currentAccount.oauthToken != nil {
        signInInProgress = true
        await currentAccount.fetchCurrentAccount()
        await currentInstance.fetchCurrentInstance()
        signInInProgress = false
      }
    }
  }
  
  private var accountsSection: some View {
    Section("Account") {
      if let accountData = currentAccount.account {
        HStack {
          AvatarView(url: accountData.avatar)
          VStack(alignment: .leading) {
            Text(appAccountsManager.currentAccount.server)
              .font(.headline)
            Text(accountData.displayName)
            Text(accountData.username)
              .font(.footnote)
              .foregroundColor(.gray)
          }
        }
        signOutButton
      } else {
        TextField("Mastodon server", text: $signInServer)
        signInButton
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }
  
  private var themeSection: some View {
    Section("Theme") {
      Toggle("Prefer dark color scheme", isOn: .init(get: {
        theme.colorScheme == "dark"
      }, set: { newValue in
        if newValue {
          theme.colorScheme = "dark"
        } else {
          theme.colorScheme = "light"
        }
      }))
      ColorPicker("Tint color", selection: $theme.tintColor)
      ColorPicker("Background color", selection: $theme.primaryBackgroundColor)
      ColorPicker("Secondary Background color", selection: $theme.secondaryBackgroundColor)
      Button {
        theme.colorScheme = "dark"
        theme.tintColor = .brand
        theme.primaryBackgroundColor = .primaryBackground
        theme.secondaryBackgroundColor = .secondaryBackground
      } label: {
        Text("Restore default")
      }
    }
    .listRowBackground(theme.primaryBackgroundColor)
  }
  
  @ViewBuilder
  private var instanceSection: some View {
    if let instanceData = currentInstance.instance {
      Section("Instance info") {
        LabeledContent("Name", value: instanceData.title)
        Text(instanceData.shortDescription)
        LabeledContent("Email", value: instanceData.email)
        LabeledContent("Version", value: instanceData.version)
        LabeledContent("Users", value: "\(instanceData.stats.userCount)")
        LabeledContent("Posts", value: "\(instanceData.stats.statusCount)")
        LabeledContent("Domains", value: "\(instanceData.stats.domainCount)")
      }
      .listRowBackground(theme.primaryBackgroundColor)
      
      Section("Instance rules") {
        ForEach(instanceData.rules) { rule in
          Text(rule.text)
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
  }
  
  private var appSection: some View {
    Section("App") {
      NavigationLink(destination: IconSelectorView()) {
        Label {
          Text("Icon selector")
        } icon: {
          if let icon = IconSelectorView.Icon(rawValue: UIApplication.shared.alternateIconName ?? "AppIcon") {
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
  
  private var signInButton: some View {
    Button {
      signInInProgress = true
      Task {
        await signIn()
      }
    } label: {
      if signInInProgress {
        ProgressView()
      } else {
        Text("Sign in")
      }
    }
  }
  
  private var signOutButton: some View {
    Button {
      appAccountsManager.delete(account: appAccountsManager.currentAccount)
    } label: {
      Text("Sign out").foregroundColor(.red)
    }

  }
  
  private func signIn() async {
    do {
      client.server = signInServer
      let oauthURL = try await client.oauthURL()
      openURL(oauthURL)
    } catch {
      signInInProgress = false
    }
  }
  
  private func continueSignIn(url: URL) async {
    do {
      let oauthToken = try await client.continueOauthFlow(url: url)
      appAccountsManager.add(account: AppAccount(server: client.server, oauthToken: oauthToken))
      await currentAccount.fetchCurrentAccount()
      await currentInstance.fetchCurrentInstance()
      signInInProgress = false
    } catch {
      signInInProgress = false
    }
  }
}
