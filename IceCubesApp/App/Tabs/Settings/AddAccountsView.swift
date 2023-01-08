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
  @EnvironmentObject private var pushNotifications: PushNotificationsService
  @EnvironmentObject private var theme: Theme
  
  @State private var instanceName: String = ""
  @State private var instance: Instance?
  @State private var isSigninIn = false
  @State private var signInClient: Client?
  @State private var instances: [InstanceSocial] = []
  @State private var instanceFetchError: String?
  
  @FocusState private var isInstanceURLFieldFocused: Bool
  
  var body: some View {
    NavigationStack {
      Form {
        TextField("Instance URL", text: $instanceName)
          .listRowBackground(theme.primaryBackgroundColor)
          .keyboardType(.URL)
          .textContentType(.URL)
          .textInputAutocapitalization(.never)
          .autocorrectionDisabled()
          .focused($isInstanceURLFieldFocused)
        if let instanceFetchError {
          Text(instanceFetchError)
        }
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
          InstanceInfoSection(instance: instance)
        } else {
          instancesListView
        }
      }
      .formStyle(.grouped)
      .navigationTitle("Add account")
      .navigationBarTitleDisplayMode(.inline)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .scrollDismissesKeyboard(.immediately)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel", action: { dismiss() })
        }
      }
      .onAppear {
        isInstanceURLFieldFocused = true
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
          } catch _ as DecodingError {
            self.instance = nil
            self.instanceFetchError = "This instance is not currently supported."
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
          Button {
            self.instanceName = instance.name
          } label: {
            VStack(alignment: .leading, spacing: 4) {
              Text(instance.name)
                .font(.headline)
                .foregroundColor(.primary)
              Text(instance.info?.shortDescription ?? "")
                .font(.body)
                .foregroundColor(.gray)
              Text("\(instance.users) users  ⸱  \(instance.statuses) posts")
                .font(.footnote)
                .foregroundColor(.gray)
            }
          }
          .listRowBackground(theme.primaryBackgroundColor)
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
      Task {
        await pushNotifications.updateSubscriptions(accounts: appAccountsManager.pushAccounts)
      }
      isSigninIn = false
      dismiss()
    } catch {
      isSigninIn = false
    }
  }
}
