import SwiftUI
import Network
import Models
import Env
import DesignSystem
import NukeUI
import Shimmer

struct AddAccountView: View {
  @Environment(\.openURL) private var openURL
  @Environment(\.dismiss) private var dismiss
  
  @EnvironmentObject private var appAccountsManager: AppAccountsManager
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var currentInstance: CurrentInstance
  @EnvironmentObject private var theme: Theme
  
  @State private var instanceName: String = ""
  @State private var instance: Instance?
  @State private var isSigninIn = false
  @State private var signInClient: Client?
  @State private var instances: [InstanceSocial] = []
  
  var body: some View {
    NavigationStack {
      Form {
        TextField("Instance url", text: $instanceName)
          .listRowBackground(theme.primaryBackgroundColor)
        if let instance {
          Button {
            isSigninIn = true
            Task {
              await signIn()
            }
          } label: {
            if isSigninIn {
              ProgressView()
            } else {
              Text("Sign in")
            }
          }
          .listRowBackground(theme.primaryBackgroundColor)
          InstanceInfoView(instance: instance)
        } else {
          instancesListView
        }
      }
      .formStyle(.grouped)
      .navigationTitle("Add account")
      .navigationBarTitleDisplayMode(.inline)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel", action: { dismiss() })
        }
      }
      .onAppear {
        let client = InstanceSocialClient()
        Task {
          self.instances = await client.fetchInstances()
        }
      }
      .onChange(of: instanceName) { newValue in
        let client = Client(server: newValue)
        Task {
          do {
            self.instance = try await client.get(endpoint: Instances.instance)
          } catch {
            self.instance = nil
          }
        }
      }
      .onOpenURL(perform: { url in
        Task {
          await continueSignIn(url: url)
        }
      })
    }
  }
  
  private var instancesListView: some View {
    Section("Suggestions") {
      if instances.isEmpty {
        ProgressView()
          .listRowBackground(theme.primaryBackgroundColor)
      } else {
        ForEach(instanceName.isEmpty ? instances : instances.filter{ $0.name.contains(instanceName.lowercased()) }) { instance in
          VStack(alignment: .leading, spacing: 4) {
            Text(instance.name)
              .font(.headline)
            Text(instance.info?.shortDescription ?? "")
              .font(.body)
              .foregroundColor(.gray)
            Text("\(instance.users) users  ⸱  \(instance.statuses) posts")
              .font(.footnote)
              .foregroundColor(.gray)
          }
          .listRowBackground(theme.primaryBackgroundColor)
          .onTapGesture {
            self.instanceName = instance.name
          }
        }
      }
    }
  }
  
  private func signIn() async {
    do {
      signInClient = .init(server: instanceName)
      if let oauthURL = try await signInClient?.oauthURL() {
        openURL(oauthURL)
      } else {
        isSigninIn = false
      }
    } catch {
      isSigninIn = false
    }
  }
  
  private func continueSignIn(url: URL) async {
    guard let client = signInClient else {
      isSigninIn = false
      return
    }
    do {
      let oauthToken = try await client.continueOauthFlow(url: url)
      appAccountsManager.add(account: AppAccount(server: client.server, oauthToken: oauthToken))
      isSigninIn = false
      dismiss()
    } catch {
      isSigninIn = false
    }
  }
}
