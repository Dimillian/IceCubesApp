import AppAccount
import Combine
import DesignSystem
import Env
import Models
import Network
import NukeUI
import SafariServices
import Shimmer
import SwiftUI

@MainActor
struct AddAccountView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.openURL) private var openURL

  @Environment(AppAccountsManager.self) private var appAccountsManager
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(PushNotificationsService.self) private var pushNotifications
  @Environment(Theme.self) private var theme

  @State private var instanceName: String = ""
  @State private var instance: Instance?
  @State private var isSigninIn = false
  @State private var signInClient: Client?
  @State private var instances: [InstanceSocial] = []
  @State private var instanceFetchError: LocalizedStringKey?
  @State private var oauthURL: URL?

  private let instanceNamePublisher = PassthroughSubject<String, Never>()

  private var sanitizedName: String {
    var name = instanceName
      .replacingOccurrences(of: "http://", with: "")
      .replacingOccurrences(of: "https://", with: "")

    if name.contains("@") {
      let parts = name.components(separatedBy: "@")
      name = parts[parts.count - 1] // [@]username@server.address.com
    }
    return name
  }

  @FocusState private var isInstanceURLFieldFocused: Bool

  private func cleanServerStr(_ server: String) -> String {
    server.replacingOccurrences(of: " ", with: "")
  }

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
          .onChange(of: instanceName) { _, _ in
            instanceName = cleanServerStr(instanceName)
          }
        if let instanceFetchError {
          Text(instanceFetchError)
        }
        if instance != nil || !instanceName.isEmpty {
          signInSection
        }
        if let instance {
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
          let instances = await client.fetchInstances()
          withAnimation {
            self.instances = instances
          }
        }
        isSigninIn = false
      }
      .onChange(of: instanceName) { _, newValue in
        instanceNamePublisher.send(newValue)
      }
      .onReceive(instanceNamePublisher.debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)) { _ in
        // let newValue = newValue
        //  .replacingOccurrences(of: "http://", with: "")
        //  .replacingOccurrences(of: "https://", with: "")
        let client = Client(server: sanitizedName)
        Task {
          do {
            // bare bones preflight for domain validity
            if client.server.contains("."), client.server.last != "." {
              let instance: Instance = try await client.get(endpoint: Instances.instance)
              withAnimation {
                self.instance = instance
                instanceName = sanitizedName // clean up the text box, principally to chop off the username if present so it's clear that you might not wind up siging in as the thing in the box
              }
              instanceFetchError = nil
            } else {
              instance = nil
              instanceFetchError = nil
            }
          } catch _ as DecodingError {
            instance = nil
            instanceFetchError = "account.add.error.instance-not-supported"
          } catch {
            instance = nil
          }
        }
      }
      .onChange(of: scenePhase) { _, newValue in
        switch newValue {
        case .active:
          isSigninIn = false
        default:
          break
        }
      }
      .onOpenURL(perform: { url in
        Task {
          await continueSignIn(url: url)
        }
      })
      .onChange(of: oauthURL) { _, newValue in
        if newValue == nil {
          isSigninIn = false
        }
      }
      #if !targetEnvironment(macCatalyst)
      .sheet(item: $oauthURL, content: { url in
        SafariView(url: url)
      })
      #endif
    }
  }

  private var signInSection: some View {
    Section {
      Button {
        withAnimation {
          isSigninIn = true
        }
        Task {
          await signIn()
        }
      } label: {
        HStack {
          Spacer()
          if isSigninIn || !sanitizedName.isEmpty && instance == nil {
            ProgressView()
              .id(sanitizedName)
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
        ForEach(sanitizedName.isEmpty ? instances : instances.filter { $0.name.contains(sanitizedName.lowercased()) }) { instance in
          Button {
            instanceName = instance.name
          } label: {
            VStack(alignment: .leading, spacing: 4) {
              Text(instance.name)
                .font(.scaledHeadline)
                .foregroundColor(.primary)
              Text(instance.info?.shortDescription ?? "")
                .font(.scaledBody)
                .foregroundStyle(Color.secondary)
              (Text("instance.list.users-\(instance.users)")
                + Text("  ⸱  ")
                + Text("instance.list.posts-\(instance.statuses)"))
                .font(.scaledFootnote)
                .foregroundStyle(Color.secondary)
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
        .foregroundStyle(.secondary)
      Text("placeholder.loading.short")
        .font(.scaledFootnote)
        .foregroundStyle(.secondary)
    }
    .redacted(reason: .placeholder)
    .allowsHitTesting(false)
    .shimmering()
    .listRowBackground(theme.primaryBackgroundColor)
  }

  private func signIn() async {
    do {
      signInClient = .init(server: sanitizedName)
      if let oauthURL = try await signInClient?.oauthURL() {
        if ProcessInfo.processInfo.isMacCatalystApp {
          openURL(oauthURL)
        } else {
          self.oauthURL = oauthURL
        }
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
      let client = Client(server: client.server, oauthToken: oauthToken)
      let account: Account = try await client.get(endpoint: Accounts.verifyCredentials)
      appAccountsManager.add(account: AppAccount(server: client.server,
                                                 accountName: "\(account.acct)@\(client.server)",
                                                 oauthToken: oauthToken))
      Task {
        pushNotifications.setAccounts(accounts: appAccountsManager.pushAccounts)
        await pushNotifications.updateSubscriptions(forceCreate: true)
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

  func makeUIViewController(context _: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
    SFSafariViewController(url: url)
  }

  func updateUIViewController(_: SFSafariViewController, context _: UIViewControllerRepresentableContext<SafariView>) {}
}
