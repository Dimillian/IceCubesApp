import Account
import AppAccount
import DesignSystem
import Env
import Models
import NetworkClient
import SwiftUI
import Timeline

struct AccountSettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL

  @Environment(PushNotificationsService.self) private var pushNotifications
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(Theme.self) private var theme
  @Environment(AppAccountsManager.self) private var appAccountsManager
  @Environment(MastodonClient.self) private var client
  @Environment(RouterPath.self) private var routerPath

  @State private var cachedPostsCount: Int = 0
  @State private var timelineCache = TimelineCache()

  let account: Account
  let appAccount: AppAccount

  var body: some View {
    Form {
      Section {
        Button {
          routerPath.presentedSheet = .accountEditInfo
        } label: {
          Label("account.action.edit-info", systemImage: "pencil")
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if currentInstance.isFiltersSupported {
          Button {
            routerPath.presentedSheet = .accountFiltersList
          } label: {
            Label("account.action.edit-filters", systemImage: "line.3.horizontal.decrease.circle")
              .frame(maxWidth: .infinity, alignment: .leading)
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
        if let subscription = pushNotifications.subscriptions.first(where: {
          $0.account.token == appAccount.oauthToken
        }) {
          NavigationLink(destination: PushNotificationsView(subscription: subscription)) {
            Label(
              "settings.general.push-notifications", systemImage: "bell.and.waves.left.and.right")
          }
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)

      Section {
        Label(
          "settings.account.cached-posts-\(String(cachedPostsCount))", systemImage: "internaldrive")
        Button("settings.account.action.delete-cache", role: .destructive) {
          Task {
            await timelineCache.clearCache(for: appAccountsManager.currentClient.id)
            cachedPostsCount = await timelineCache.cachedPostsCount(
              for: appAccountsManager.currentClient.id)
          }
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)

      Section {
        Button {
          openURL(URL(string: "https://\(client.server)/settings/profile")!)
        } label: {
          Text("account.action.more")
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)

      Section {
        Button(role: .destructive) {
          if let token = appAccount.oauthToken {
            Task {
              let client = MastodonClient(server: appAccount.server, oauthToken: token)
              await timelineCache.clearCache(for: client.id)
              if let sub = pushNotifications.subscriptions.first(where: {
                $0.account.token == token
              }) {
                await sub.deleteSubscription()
              }
              appAccountsManager.delete(account: appAccount)
              Telemetry.signal("account.removed")
              dismiss()
            }
          }
        } label: {
          Label("account.action.logout", systemImage: "trash")
            .frame(maxWidth: .infinity)
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        HStack {
          AvatarView(account.avatar, config: .embed)
          Text(account.safeDisplayName)
            .font(.headline)
        }
      }
    }
    .task {
      cachedPostsCount = await timelineCache.cachedPostsCount(
        for: appAccountsManager.currentClient.id)
    }
    .navigationTitle(account.safeDisplayName)
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
    #endif
  }
}
