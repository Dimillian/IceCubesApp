import DesignSystem
import Models
import NetworkClient
import SwiftUI

@MainActor
struct NotificationsPolicyView: View {
  @Environment(\.dismiss) private var dismiss

  @Environment(MastodonClient.self) private var client
  @Environment(Theme.self) private var theme

  @State private var policy: NotificationsPolicy?
  @State private var isUpdating: Bool = false

  var body: some View {
    NavigationStack {
      Form {
        Section("notifications.content-filter.title-inline") {
          Picker(
            selection: .init(
              get: {
                policy?.forNotFollowing ?? .drop
              },
              set: { policy in
                self.policy?.forNotFollowing = policy
                Task { await updatePolicy() }
              })
          ) {
            pickerMenu
          } label: {
            makePickerLabel(
              title: "notifications.content-filter.peopleYouDontFollow",
              subtitle: "Until you manually approve them")
          }

          Picker(
            selection: .init(
              get: {
                policy?.forNotFollowers ?? .drop
              },
              set: { policy in
                self.policy?.forNotFollowers = policy
                Task { await updatePolicy() }
              })
          ) {
            pickerMenu
          } label: {
            makePickerLabel(
              title: "notifications.content-filter.peopleNotFollowingYou",
              subtitle: "And following you for less than 3 days")
          }

          Picker(
            selection: .init(
              get: {
                policy?.forNewAccounts ?? .drop
              },
              set: { policy in
                self.policy?.forNewAccounts = policy
                Task { await updatePolicy() }
              })
          ) {
            pickerMenu
          } label: {
            makePickerLabel(
              title: "notifications.content-filter.newAccounts",
              subtitle: "Created within the past 30 days")
          }

          Picker(
            selection: .init(
              get: {
                policy?.forPrivateMentions ?? .drop
              },
              set: { policy in
                self.policy?.forPrivateMentions = policy
                Task { await updatePolicy() }
              })
          ) {
            pickerMenu
          } label: {
            makePickerLabel(
              title: "notifications.content-filter.privateMentions",
              subtitle: "Unless it's in reply to your own mention or if you follow the sender")
          }

          Picker(
            selection: .init(
              get: {
                policy?.forLimitedAccounts ?? .drop
              },
              set: { policy in
                self.policy?.forLimitedAccounts = policy
                Task { await updatePolicy() }
              })
          ) {
            pickerMenu
          } label: {
            VStack(alignment: .leading) {
              makePickerLabel(
                title: "Moderated accounts",
                subtitle: "Limited by server moderators")
            }
          }
        }
        #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor.opacity(0.3))
        #endif
      }
      .formStyle(.grouped)
      .navigationTitle("notifications.content-filter.title")
      .navigationBarTitleDisplayMode(.inline)
      .scrollContentBackground(.hidden)
      .toolbar { CloseToolbarItem() }
      .disabled(policy == nil || isUpdating)
      .task {
        await getPolicy()
      }
      .redacted(reason: policy == nil ? .placeholder : [])
    }
    .presentationDetents([.height(500)])
    .presentationBackground(.thinMaterial)
  }

  private var pickerMenu: some View {
    ForEach(NotificationsPolicy.Policy.allCases, id: \.self) { policy in
      Text(policy.rawValue.capitalized)
    }
  }

  private func makePickerLabel(title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View
  {
    VStack(alignment: .leading) {
      Text(title)
        .font(.callout)
      Text(subtitle)
        .foregroundStyle(.secondary)
        .font(.footnote)
    }
  }

  private func getPolicy() async {
    defer {
      isUpdating = false
    }
    do {
      isUpdating = true
      policy = try await client.get(endpoint: Notifications.policy, forceVersion: .v2)
    } catch {
      dismiss()
    }
  }

  private func updatePolicy() async {
    if let policy {
      defer {
        isUpdating = false
      }
      do {
        isUpdating = true
        self.policy = try await client.put(
          endpoint: Notifications.putPolicy(policy: policy), forceVersion: .v2)
      } catch {}
    }
  }
}
