import SwiftUI
import Network
import Models
import Env
import DesignSystem
import NukeUI
import Shimmer

struct AddAccountView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  
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
          signInSection
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
        isSigninIn = false
      }
      .onChange(of: instanceName) { newValue in
        let client = Client(server: newValue)
        Task {
          do {
            self.instance = try await client.get(endpoint: Instances.instance)
            self.instanceFetchError = nil
          } catch _ as DecodingError {
            self.instance = nil
            self.instanceFetchError = "This instance is not currently supported."
          } catch {
            self.instance = nil
          }
        }
      }
      .onChange(of: scenePhase, perform: { scenePhase in
        switch scenePhase {
        case .active:
          isSigninIn = false
        default:
          break
        }
      })
      .onOpenURL(perform: { url in
        Task {
          await continueSignIn(url: url)
        }
      })
    }
  }
  
  private var signInSection: some View {
    Section {
      Button {
        isSigninIn = true
        Task {
          await signIn()
        }
      } label: {
        HStack {
          Spacer()
          if isSigninIn {
            ProgressView()
              .tint(theme.labelColor)
          } else {
            Text("Sign in")
              .font(.headline)
          }
          Spacer()
        }
      }
      .buttonStyle(.borderedProminent)
    }
    .listRowBackground(theme.tintColor)
  }
  
  private var instancesListView: some View {
    Section("Suggestions") {
      if instances.isEmpty {
        placeholderRow
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
  
  private var placeholderRow: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Loading...")
        .font(.headline)
        .foregroundColor(.primary)
      Text("Loading, loading, loading ....")
        .font(.body)
        .foregroundColor(.gray)
      Text("Loading ...")
        .font(.footnote)
        .foregroundColor(.gray)
    }
    .redacted(reason: .placeholder)
    .shimmering()
    .listRowBackground(theme.primaryBackgroundColor)
  }
  
  private func signIn() async {
    do {
      signInClient = .init(server: instanceName)
      if let oauthURL = try await signInClient?.oauthURL() {
        await UIApplication.shared.open(oauthURL)
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
