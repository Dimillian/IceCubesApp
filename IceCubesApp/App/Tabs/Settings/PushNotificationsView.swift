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
  @EnvironmentObject private var pushNotifications: PushNotificationsService
  
  @State private var subscriptions: [PushSubscription] = []
    
  var body: some View {
    Form {
      Section {
        Toggle(isOn: $pushNotifications.isPushEnabled) {
          Text("Push notifications")
        }
      } footer: {
        Text("Receive push notifications on new activities")
      }
      .listRowBackground(theme.primaryBackgroundColor)
      
      if pushNotifications.isPushEnabled {
        Section {
          Toggle(isOn: $pushNotifications.isMentionNotificationEnabled) {
            Label("Mentions", systemImage: "at")
          }
          Toggle(isOn: $pushNotifications.isFollowNotificationEnabled) {
            Label("Follows", systemImage: "person.badge.plus")
          }
          Toggle(isOn: $pushNotifications.isFavoriteNotificationEnabled) {
            Label("Favorites", systemImage: "star")
          }
          Toggle(isOn: $pushNotifications.isReblogNotificationEnabled) {
            Label("Boosts", systemImage: "arrow.left.arrow.right.circle")
          }
          Toggle(isOn: $pushNotifications.isPollNotificationEnabled) {
            Label("Polls Results", systemImage: "chart.bar")
          }
          Toggle(isOn: $pushNotifications.isNewPostsNotificationEnabled) {
            Label("New Posts", systemImage: "bubble.right")
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
    .onChange(of: pushNotifications.isNewPostsNotificationEnabled) { _ in
      updateSubscriptions()
    }
  }
  
  private func updateSubscriptions() {
    Task {
      await pushNotifications.updateSubscriptions(accounts: appAccountsManager.pushAccounts)
    }
  }
}
