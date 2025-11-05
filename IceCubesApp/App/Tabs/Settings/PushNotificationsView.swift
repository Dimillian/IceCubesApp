import AppAccount
import DesignSystem
import Env
import Models
import NetworkClient
import NukeUI
import SwiftUI
import UserNotifications

@MainActor
struct PushNotificationsView: View {
  @Environment(Theme.self) private var theme
  @Environment(AppAccountsManager.self) private var appAccountsManager
  @Environment(PushNotificationsService.self) private var pushNotifications

  @State public var subscription: PushNotificationSubscriptionSettings

  var body: some View {
    Form {
      Section {
        Toggle(
          isOn: .init(
            get: {
              subscription.isEnabled
            },
            set: { newValue in
              subscription.isEnabled = newValue
              if newValue {
                updateSubscription()
              } else {
                deleteSubscription()
              }
            })
        ) {
          Text("settings.push.main-toggle")
        }
      } footer: {
        Text("settings.push.main-toggle.description")
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif

      if subscription.isEnabled {
        Section {
          Toggle(
            isOn: .init(
              get: {
                subscription.isMentionNotificationEnabled
              },
              set: { newValue in
                subscription.isMentionNotificationEnabled = newValue
                updateSubscription()
              })
          ) {
            Label("settings.push.mentions", systemImage: "at")
          }
          Toggle(
            isOn: .init(
              get: {
                subscription.isFollowNotificationEnabled
              },
              set: { newValue in
                subscription.isFollowNotificationEnabled = newValue
                updateSubscription()
              })
          ) {
            Label("settings.push.follows", systemImage: "person.badge.plus")
          }
          Toggle(
            isOn: .init(
              get: {
                subscription.isFavoriteNotificationEnabled
              },
              set: { newValue in
                subscription.isFavoriteNotificationEnabled = newValue
                updateSubscription()
              })
          ) {
            Label("settings.push.favorites", systemImage: "star")
          }
          Toggle(
            isOn: .init(
              get: {
                subscription.isReblogNotificationEnabled
              },
              set: { newValue in
                subscription.isReblogNotificationEnabled = newValue
                updateSubscription()
              })
          ) {
            Label("settings.push.boosts", systemImage: "arrow.2.squarepath")
          }
          Toggle(
            isOn: .init(
              get: {
                subscription.isPollNotificationEnabled
              },
              set: { newValue in
                subscription.isPollNotificationEnabled = newValue
                updateSubscription()
              })
          ) {
            Label("settings.push.polls", systemImage: "chart.bar")
          }
          Toggle(
            isOn: .init(
              get: {
                subscription.isNewPostsNotificationEnabled
              },
              set: { newValue in
                subscription.isNewPostsNotificationEnabled = newValue
                updateSubscription()
              })
          ) {
            Label("settings.push.new-posts", systemImage: "bubble.right")
          }
        }
        #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor)
        #endif
      }

      Section {
        Button("settings.push.duplicate.button.fix") {
          Task {
            await subscription.deleteSubscription()
            await subscription.updateSubscription()
          }
        }
      } header: {
        Text("settings.push.duplicate.title")
      } footer: {
        Text("settings.push.duplicate.footer")
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
    .navigationTitle("settings.push.navigation-title")
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
    #endif
    .task {
      await subscription.fetchSubscription()
    }
  }

  private func updateSubscription() {
    Task {
      await subscription.updateSubscription()
    }
  }

  private func deleteSubscription() {
    Task {
      await subscription.deleteSubscription()
    }
  }
}
