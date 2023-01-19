import AppAccount
import Combine
import DesignSystem
import Env
import Models
import Network
import NukeUI
import Shimmer
import SwiftUI
import SafariServices

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
  @State private var instanceFetchError: LocalizedStringKey?
  @State private var oauthURL: URL?

  private let instanceNamePublisher = PassthroughSubject<String, Never>()

  @FocusState private var isInstanceURLFieldFocused: Bool

  var body: some View {
    NavigationStack {
      Form {
        TextField("instance.url", text: $instanceName)
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
      .navigationTitle("account.add.navigation-title")
      .navigationBarTitleDisplayMode(.inline)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .scrollDismissesKeyboard(.immediately)
      .toolbar {
        if !appAccountsManager.availableAccounts.isEmpty {
          ToolbarItem(placement: .navigationBarLeading) {
            Button("action.cancel", action: { dismiss() })
          }
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
        instanceNamePublisher.send(newValue)
      }
      .onReceive(instanceNamePublisher.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)) { newValue in
        let client = Client(server: newValue)
        Task {
          do {
            self.instance = try await client.get(endpoint: Instances.instance)
            self.instanceFetchError = nil
          } catch _ as DecodingError {
            self.instance = nil
            self.instanceFetchError = "account.add.error.instance-not-supported"
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
      .sheet(item: $oauthURL, content: { url in
        SafariView(url: url)
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
            Text("account.add.sign-in")
              .font(.scaledHeadline)
          }
          Spacer()
        }
      }
      .buttonStyle(.borderedProminent)
    }
    .listRowBackground(theme.tintColor)
  }

  private var instancesListView: some View {
    Section("instance.suggestions") {
      if instances.isEmpty {
        placeholderRow
      } else {
        ForEach(instanceName.isEmpty ? instances : instances.filter { $0.name.contains(instanceName.lowercased()) }) { instance in
          Button {
            self.instanceName = instance.name
          } label: {
            VStack(alignment: .leading, spacing: 4) {
              Text(instance.name)
                .font(.scaledHeadline)
                .foregroundColor(.primary)
              Text(instance.info?.shortDescription ?? "")
                .font(.scaledBody)
                .foregroundColor(.gray)
              (Text("instance.list.users-\(instance.users)")
                + Text("  ⸱  ")
                + Text("instance.list.posts-\(instance.statuses)"))
              .font(.scaledFootnote)
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
      Text("placeholder.loading.short")
        .font(.scaledHeadline)
        .foregroundColor(.primary)
      Text("placeholder.loading.long")
        .font(.scaledBody)
        .foregroundColor(.gray)
      Text("placeholder.loading.short")
        .font(.scaledFootnote)
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
        self.oauthURL = oauthURL
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
      oauthURL = nil
      let oauthToken = try await client.continueOauthFlow(url: url)
      appAccountsManager.add(account: AppAccount(server: client.server, oauthToken: oauthToken))
      Task {
        await pushNotifications.updateSubscriptions(accounts: appAccountsManager.pushAccounts)
      }
      isSigninIn = false
      dismiss()
    } catch {
      oauthURL = nil
      isSigninIn = false
    }
  }
}

struct SafariView: UIViewControllerRepresentable {
  let url: URL

  func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
    SFSafariViewController(url: url)
  }
  
  func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {

  }
}
