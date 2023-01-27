import Account
import AppAccount
import DesignSystem
import Env
import Models
import SwiftUI

struct AccountSettingsView: View {
  @Environment(\.dismiss) private var dismiss

  @EnvironmentObject private var pushNotifications: PushNotificationsService
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var currentInstance: CurrentInstance
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var appAccountsManager: AppAccountsManager

  @State private var isEditingAccount: Bool = false
  @State private var isEditingFilters: Bool = false

  let account: Account
  let appAccount: AppAccount

  var body: some View {
    Form {
      Section {
        Label("account.action.edit-info", systemImage: "pencil")
          .onTapGesture {
            isEditingAccount = true
          }
        if currentInstance.isFiltersSupported {
          Label("account.action.edit-filters", systemImage: "line.3.horizontal.decrease.circle")
            .onTapGesture {
              isEditingFilters = true
            }
        }
        if let subscription = pushNotifications.subscriptions.first(where: { $0.account.token == appAccount.oauthToken }) {
          NavigationLink(destination: PushNotificationsView(subscription: subscription)) {
            Label("settings.general.push-notifications", systemImage: "bell.and.waves.left.and.right")
          }
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
      Section {
        Button(role: .destructive) {
          if let token = appAccount.oauthToken {
            Task {
              if let sub = pushNotifications.subscriptions.first(where: { $0.account.token == token }) {
                await sub.deleteSubscription()
              }
              appAccountsManager.delete(account: appAccount)
              dismiss()
            }
          }
        } label: {
          Text("account.action.logout")
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
    .navigationTitle(account.safeDisplayName)
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }
}
