import Account
import AppAccount
import DesignSystem
import Env
import Models
import SwiftUI
import Timeline
import Network

struct AccountSettingsView: View {
  @Environment(\.dismiss) private var dismiss

  @EnvironmentObject private var pushNotifications: PushNotificationsService
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var currentInstance: CurrentInstance
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var appAccountsManager: AppAccountsManager

  @State private var isEditingAccount: Bool = false
  @State private var isEditingFilters: Bool = false
  @State private var cachedPostsCount: Int = 0

  let account: Account
  let appAccount: AppAccount

  var body: some View {
    Form {
      Section {
        Button {
          isEditingAccount = true
        } label: {
          Label("account.action.edit-info", systemImage: "pencil")
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

        if currentInstance.isFiltersSupported {
          Button {
            isEditingFilters = true
          } label: {
            Label("account.action.edit-filters", systemImage: "line.3.horizontal.decrease.circle")
              .frame(maxWidth: .infinity, alignment: .leading)
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
        if let subscription = pushNotifications.subscriptions.first(where: { $0.account.token == appAccount.oauthToken }) {
          NavigationLink(destination: PushNotificationsView(subscription: subscription)) {
            Label("settings.general.push-notifications", systemImage: "bell.and.waves.left.and.right")
          }
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)

      Section {
        Label("settings.account.cached-posts-\(String(cachedPostsCount))", systemImage: "internaldrive")
        Button("settings.account.action.delete-cache", role: .destructive) {
          Task {
            await TimelineCache.shared.clearCache(for: appAccountsManager.currentClient)
            cachedPostsCount = await TimelineCache.shared.cachedPostsCount(for: appAccountsManager.currentClient)
          }
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)

      Section {
        Button(role: .destructive) {
          if let token = appAccount.oauthToken {
            Task {
              let client = Client(server: appAccount.server, oauthToken: token)
              await TimelineCache.shared.clearCache(for: client)
              if let sub = pushNotifications.subscriptions.first(where: { $0.account.token == token }) {
                await sub.deleteSubscription()
              }
              appAccountsManager.delete(account: appAccount)
              dismiss()
            }
          }
        } label: {
          Text("account.action.logout")
            .frame(maxWidth: .infinity)
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .sheet(isPresented: $isEditingAccount, content: {
      EditAccountView()
    })
    .sheet(isPresented: $isEditingFilters, content: {
      FiltersListView()
    })
    .toolbar {
      ToolbarItem(placement: .principal) {
        HStack {
          AvatarView(url: account.avatar, size: .embed)
          Text(account.safeDisplayName)
            .font(.headline)
        }
      }
    }
    .task {
      cachedPostsCount = await TimelineCache.shared.cachedPostsCount(for: appAccountsManager.currentClient)
    }
    .navigationTitle(account.safeDisplayName)
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }
}
