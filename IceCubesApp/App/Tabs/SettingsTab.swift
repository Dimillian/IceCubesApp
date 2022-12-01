import SwiftUI
import Timeline
import Routeur
import Network
import Account
import Models

struct SettingsTabs: View {
  @Environment(\.openURL) private var openURL
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var appAccountsManager: AppAccountsManager
  
  @State private var signInInProgress = false
  @State private var accountData: Account?
  @State private var signInServer = IceCubesApp.defaultServer
  
  var body: some View {
    NavigationStack {
      Form {
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
        signInInProgress = false
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
      signInInProgress = false
    } catch {
      signInInProgress = false
    }
  }
  
  private func refreshAccountInfo() async {
    accountData = try? await client.get(endpoint: Accounts.verifyCredentials)
  }
}
