import SwiftUI
import Account
import DesignSystem
import Env
import Models
import AppAccount

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
        NavigationLink(value: RouterDestinations.accountDetailWithAccount(account: account)) {
          Label("See Profile", systemImage: "person.crop.circle")
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
      Section {
        Label("Edit profile", systemImage: "pencil")
          .onTapGesture {
            isEditingAccount = true
          }
        if currentInstance.isFiltersSupported {
          Label("Edit Filters", systemImage: "line.3.horizontal.decrease.circle")
            .onTapGesture {
              isEditingFilters = true
            }
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
      Section {
        Button(role: .destructive) {
          if let token = appAccount.oauthToken {
            Task {
              await pushNotifications.deleteSubscriptions(accounts: [.init(server: appAccount.server,
                                                                           token: token,
                                                                           accountName: appAccount.accountName)])
              appAccountsManager.delete(account: appAccount)
              dismiss()
            }
          }
        } label: {
          Text("Logout account")
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
