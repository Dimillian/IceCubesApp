import AppAccount
import AuthenticationServices
import Combine
import DesignSystem
import Env
import Models
import NetworkClient
import NukeUI
import SafariServices
import SwiftUI

@MainActor
struct AddAccountView: View {
  @Environment(\.webAuthenticationSession) private var webAuthenticationSession
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
  @State private var signInClient: MastodonClient?
  @State private var instances: [InstanceSocial] = []
  @State private var instanceFetchError: LocalizedStringKey?
  @State private var instanceSocialClient = InstanceSocialClient()
  @State private var searchingTask = Task<Void, Never> {}
  @State private var getInstanceDetailTask = Task<Void, Never> {}

  private let instanceNamePublisher = PassthroughSubject<String, Never>()

  private var sanitizedName: String {
    var name =
      instanceName
      .replacingOccurrences(of: "http://", with: "")
      .replacingOccurrences(of: "https://", with: "")

    if name.contains("@") {
      let parts = name.components(separatedBy: "@")
      name = parts[parts.count - 1]  // [@]username@server.address.com
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
          #if !os(visionOS)
            .listRowBackground(theme.primaryBackgroundColor)
          #endif
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
      #if !os(visionOS)
        .scrollContentBackground(.hidden)
        .background(theme.secondaryBackgroundColor)
        .scrollDismissesKeyboard(.immediately)
      #endif
      .toolbar {
        CancelToolbarItem()
      }
      .onAppear {
        isInstanceURLFieldFocused = true
        let instanceName = instanceName
        Task {
          let instances = await instanceSocialClient.fetchInstances(keyword: instanceName)
          withAnimation {
            self.instances = instances
          }
        }
        isSigninIn = false
      }
      .onChange(of: instanceName) {
        searchingTask.cancel()
        let instanceName = instanceName
        let instanceSocialClient = instanceSocialClient
        searchingTask = Task {
          try? await Task.sleep(for: .seconds(0.1))
          guard !Task.isCancelled else { return }

          let instances = await instanceSocialClient.fetchInstances(keyword: instanceName)
          withAnimation {
            self.instances = instances
          }
        }

        getInstanceDetailTask.cancel()
        getInstanceDetailTask = Task {
          try? await Task.sleep(for: .seconds(0.1))
          guard !Task.isCancelled else { return }

          do {
            // bare bones preflight for domain validity
            let instanceDetailClient = MastodonClient(server: sanitizedName, version: .v2)
            if instanceDetailClient.server.contains("."),
              instanceDetailClient.server.last != "."
            {
              let instance: Instance = try await instanceDetailClient.get(
                endpoint: Instances.instance)
              withAnimation {
                self.instance = instance
                self.instanceName = sanitizedName  // clean up the text box, principally to chop off the username if present so it's clear that you might not wind up siging in as the thing in the box
              }
              instanceFetchError = nil
            } else {
              instance = nil
              instanceFetchError = nil
            }
          } catch _ as ServerError {
            instance = nil
            instanceFetchError = "account.add.error.instance-not-supported"
          } catch {
            instance = nil
            instanceFetchError = nil
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
    }
  }

  private var signInSection: some View {
    Section {
      if #available(iOS 26.0, *) {
        signinButton
          .buttonStyle(.glassProminent)
      } else {
        signinButton
          .buttonStyle(.borderedProminent)
      }
    }
  }

  private var signinButton: some View {
    Button {
      withAnimation {
        isSigninIn = true
      }
      Task {
        await signIn()
      }
    } label: {
      HStack {
        if isSigninIn || !sanitizedName.isEmpty && instance == nil {
          ProgressView()
            .id(sanitizedName)
            .tint(theme.labelColor)
        } else {
          Text("account.add.sign-in")
            .font(.scaledHeadline)
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: 44)
    }
    .listRowInsets(.init())
    .listRowBackground(Color.clear)
  }

  private var instancesListView: some View {
    Section("instance.suggestions") {
      if instances.isEmpty {
        placeholderRow
      } else {
        ForEach(instances) { instance in
          Button {
            instanceName = instance.name
          } label: {
            VStack(alignment: .leading, spacing: 4) {
              LazyImage(url: instance.thumbnail) { state in
                if let image = state.image {
                  image
                    .resizable()
                    .scaledToFill()
                } else {
                  Rectangle().fill(theme.tintColor.opacity(0.1))
                }
              }
              .frame(height: 100)
              .frame(maxWidth: .infinity)
              .clipped()

              VStack(alignment: .leading) {
                HStack {
                  Text(instance.name)
                    .font(.scaledHeadline)
                    .foregroundColor(.primary)
                  Spacer()
                  (Text("instance.list.users-\(formatAsNumber(instance.users))")
                    + Text("  ⸱  ")
                    + Text("instance.list.posts-\(formatAsNumber(instance.statuses))"))
                    .foregroundStyle(theme.tintColor)
                }
                .padding(.bottom, 5)
                Text(
                  instance.info?.shortDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
                    ?? ""
                )
                .foregroundStyle(Color.secondary)
                .lineLimit(10)
              }
              .font(.scaledFootnote)
              .padding(10)
            }
          }
          #if !os(visionOS)
            .background(theme.primaryBackgroundColor)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
            .listRowSeparator(.hidden)
            .clipShape(RoundedRectangle(cornerRadius: 4))
          #endif
        }
      }
    }
  }

  private func formatAsNumber(_ string: String) -> String {
    (Int(string) ?? 0)
      .formatted(
        .number
          .notation(.compactName)
          .locale(.current)
      )
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
    #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  private func signIn() async {
    signInClient = .init(server: sanitizedName)
    if let oauthURL = try? await signInClient?.oauthURL(),
      let url = try? await webAuthenticationSession.authenticate(
        using: oauthURL,
        callbackURLScheme: AppInfo.scheme.replacingOccurrences(of: "://", with: ""))
    {
      await continueSignIn(url: url)
    } else {
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
      let client = MastodonClient(server: client.server, oauthToken: oauthToken)
      let account: Account = try await client.get(endpoint: Accounts.verifyCredentials)
      Telemetry.signal("account.added")
      appAccountsManager.add(
        account: AppAccount(
          server: client.server,
          accountName: "\(account.acct)@\(client.server)",
          oauthToken: oauthToken))
      Task {
        pushNotifications.setAccounts(accounts: appAccountsManager.pushAccounts)
        await pushNotifications.updateSubscriptions(forceCreate: true)
      }
      isSigninIn = false
      dismiss()
    } catch {
      isSigninIn = false
    }
  }
}
