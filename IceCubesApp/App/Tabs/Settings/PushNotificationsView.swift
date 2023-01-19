import AppAccount
import DesignSystem
import Env
import Models
import Network
import NukeUI
import SwiftUI
import UserNotifications

struct PushNotificationsView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var appAccountsManager: AppAccountsManager
  @EnvironmentObject private var pushNotifications: PushNotificationsService

  @State private var subscriptions: [PushSubscription] = []

  var body: some View {
    Form {
      Section {
        Toggle(isOn: $pushNotifications.isPushEnabled) {
          Text("settings.push.main-toggle")
        }
      } footer: {
        Text("settings.push.main-toggle.description")
      }
      .listRowBackground(theme.primaryBackgroundColor)

      if pushNotifications.isPushEnabled {
        Section {
          Toggle(isOn: $pushNotifications.isMentionNotificationEnabled) {
            Label("settings.push.mentions", systemImage: "at")
          }
          Toggle(isOn: $pushNotifications.isFollowNotificationEnabled) {
            Label("settings.push.follows", systemImage: "person.badge.plus")
          }
          Toggle(isOn: $pushNotifications.isFavoriteNotificationEnabled) {
            Label("settings.push.favorites", systemImage: "star")
          }
          Toggle(isOn: $pushNotifications.isReblogNotificationEnabled) {
            Label("settings.push.boosts", systemImage: "arrow.left.arrow.right.circle")
          }
          Toggle(isOn: $pushNotifications.isPollNotificationEnabled) {
            Label("settings.push.polls", systemImage: "chart.bar")
          }
          Toggle(isOn: $pushNotifications.isNewPostsNotificationEnabled) {
            Label("settings.push.new-posts", systemImage: "bubble.right")
          }
        }
        .listRowBackground(theme.primaryBackgroundColor)
        .transition(.move(edge: .bottom))
      }
    }
    .navigationTitle("settings.push.navigation-title")
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
