import SwiftUI
import Models
import DesignSystem
import NukeUI
import Network
import UserNotifications
import Env

struct PushNotificationsView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var appAccountsManager: AppAccountsManager
  @EnvironmentObject private var pushNotifications: PushNotifications
  
  @State private var subscriptions: [PushSubscription] = []
    
  var body: some View {
    Form {
      Section {
        Toggle(isOn: $pushNotifications.isPushEnabled) {
          Text("Push notification")
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
      
      if pushNotifications.isPushEnabled {
        Section {
          Toggle(isOn: $pushNotifications.isFollowNotificationEnabled) {
            Text("Follow notification")
          }
          Toggle(isOn: $pushNotifications.isFavoriteNotificationEnabled) {
            Text("Favorite notification")
          }
          Toggle(isOn: $pushNotifications.isReblogNotificationEnabled) {
            Text("Boost notification")
          }
          Toggle(isOn: $pushNotifications.isMentionNotificationEnabled) {
            Text("Mention notification")
          }
          Toggle(isOn: $pushNotifications.isPollNotificationEnabled) {
            Text("Polls notification")
          }
        }
        .listRowBackground(theme.primaryBackgroundColor)
        .transition(.move(edge: .bottom))
      }
    }
    .navigationTitle("Push Notifications")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
    .onAppear {
      Task {
        await pushNotifications.fetchSubscriptions(accounts: appAccountsManager.pushAccounts)
      }
    }
    .onChange(of: pushNotifications.isPushEnabled) { newValue in
      pushNotifications.isUserPushEnabled = newValue
      if !newValue {
        Task {
          await pushNotifications.deleteSubscriptions(accounts: appAccountsManager.pushAccounts)
        }
      } else {
        updateSubscriptions()
      }
    }
    .onChange(of: pushNotifications.isFollowNotificationEnabled) { _ in
      updateSubscriptions()
    }
    .onChange(of: pushNotifications.isPollNotificationEnabled) { _ in
      updateSubscriptions()
    }
    .onChange(of: pushNotifications.isReblogNotificationEnabled) { _ in
      updateSubscriptions()
    }
    .onChange(of: pushNotifications.isMentionNotificationEnabled) { _ in
      updateSubscriptions()
    }
    .onChange(of: pushNotifications.isFavoriteNotificationEnabled) { _ in
      updateSubscriptions()
    }
  }
  
  private func updateSubscriptions() {
    Task {
      await pushNotifications.updateSubscriptions(accounts: appAccountsManager.pushAccounts)
    }
  }
}
