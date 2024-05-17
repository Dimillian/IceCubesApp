import DesignSystem
import Models
import Network
import SwiftUI

@MainActor
struct NotificationsPolicyView: View {
  @Environment(\.dismiss) private var dismiss

  @Environment(Client.self) private var client
  @Environment(Theme.self) private var theme

  @State private var policy: NotificationsPolicy?
  @State private var isUpdating: Bool = false

  var body: some View {
    NavigationStack {
      Form {
        Section("notifications.content-filter.title-inline") {
          Toggle(isOn: .init(get: { policy?.filterNotFollowing == true },
                             set: { newValue in
                               policy?.filterNotFollowing = newValue
                               Task { await updatePolicy() }
                             }), label: {
              Text("notifications.content-filter.peopleYouDontFollow")
            })
          Toggle(isOn: .init(get: { policy?.filterNotFollowers == true },
                             set: { newValue in
                               policy?.filterNotFollowers = newValue
                               Task { await updatePolicy() }
                             }), label: {
              Text("notifications.content-filter.peopleNotFollowingYou")
            })
          Toggle(isOn: .init(get: { policy?.filterNewAccounts == true },
                             set: { newValue in
                               policy?.filterNewAccounts = newValue
                               Task { await updatePolicy() }
                             }), label: {
              Text("notifications.content-filter.newAccounts")
            })
          Toggle(isOn: .init(get: { policy?.filterPrivateMentions == true },
                             set: { newValue in
                               policy?.filterPrivateMentions = newValue
                               Task { await updatePolicy() }
                             }), label: {
              Text("notifications.content-filter.privateMentions")
            })
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
    }
    .presentationDetents([.medium])
    .presentationBackground(.thinMaterial)
  }

  private func getPolicy() async {
    defer {
      isUpdating = false
    }
    do {
      isUpdating = true
      policy = try await client.get(endpoint: Notifications.policy)
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
        self.policy = try await client.put(endpoint: Notifications.putPolicy(policy: policy))
      } catch {}
    }
  }
}
