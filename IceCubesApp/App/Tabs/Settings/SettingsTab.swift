import SwiftUI
import Timeline
import Env
import Network
import Account
import Models

struct SettingsTabs: View {
  @Environment(\.openURL) private var openURL
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var appAccountsManager: AppAccountsManager
  
  @State private var signInInProgress = false
  @State private var accountData: Account?
  @State private var instanceData: Instance?
  @State private var signInServer = IceCubesApp.defaultServer
  
  var body: some View {
    NavigationStack {
      Form {
        appSection
        accountSection
        instanceSection
      }
      .onOpenURL(perform: { url in
        Task {
          await continueSignIn(url: url)
        }
      })
      .navigationTitle(Text("Settings"))
      .navigationBarTitleDisplayMode(.inline)
    }
    .task {
      if appAccountsManager.currentAccount.oauthToken != nil {
        signInInProgress = true
        await refreshAccountInfo()
        await refreshInstanceInfo()
        signInInProgress = false
      }
    }
  }
  
  private var accountSection: some View {
    Section("Account") {
      if let accountData {
        VStack(alignment: .leading) {
          Text(appAccountsManager.currentAccount.server)
            .font(.headline)
          Text(accountData.displayName)
          Text(accountData.username)
            .font(.footnote)
            .foregroundColor(.gray)
        }
        signOutButton
      } else {
        TextField("Mastodon server", text: $signInServer)
        signInButton
      }
    }
  }
  
  @ViewBuilder
  private var instanceSection: some View {
    if let instanceData {
      Section("Instance info") {
        LabeledContent("Name", value: instanceData.title)
        Text(instanceData.shortDescription)
        LabeledContent("Email", value: instanceData.email)
        LabeledContent("Version", value: instanceData.version)
        LabeledContent("Users", value: "\(instanceData.stats.userCount)")
        LabeledContent("Status", value: "\(instanceData.stats.statusCount)")
        LabeledContent("Domains", value: "\(instanceData.stats.domainCount)")
      }
    }
  }
  
  private var appSection: some View {
    Section("App") {
      NavigationLink(destination: IconSelectorView()) {
        Label {
          Text("Icon selector")
        } icon: {
          Image(uiImage: .init(named: UIApplication.shared.alternateIconName ?? "AppIconInApp")!)
            .resizable()
            .frame(width: 25, height: 25)
            .cornerRadius(4)
        }
      }
      Link(destination: URL(string: "https://github.com/Dimillian/IceCubesApp")!) {
        Text("https://github.com/Dimillian/IceCubesApp")
      }
    }
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
      instanceData = nil
      accountData = nil
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
      await refreshAccountInfo()
      await refreshInstanceInfo()
      signInInProgress = false
    } catch {
      signInInProgress = false
    }
  }
  
  private func refreshAccountInfo() async {
    accountData = try? await client.get(endpoint: Accounts.verifyCredentials)
  }
  
  private func refreshInstanceInfo() async {
    instanceData = try? await client.get(endpoint: Instances.instance)
  }
}
