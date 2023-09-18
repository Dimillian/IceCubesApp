import Combine
import Foundation
import Models
import Network
import Observation
import SwiftUI

@MainActor
@Observable public class FollowButtonViewModel {
  var client: Client?

  public let accountId: String
  public let shouldDisplayNotify: Bool
  public let relationshipUpdated: (Relationship) -> Void
  public private(set) var relationship: Relationship
  public private(set) var isUpdating: Bool = false

  public init(accountId: String,
              relationship: Relationship,
              shouldDisplayNotify: Bool,
              relationshipUpdated: @escaping ((Relationship) -> Void))
  {
    self.accountId = accountId
    self.relationship = relationship
    self.shouldDisplayNotify = shouldDisplayNotify
    self.relationshipUpdated = relationshipUpdated
  }

  func follow() async {
    guard let client else { return }
    isUpdating = true
    do {
      relationship = try await client.post(endpoint: Accounts.follow(id: accountId, notify: false, reblogs: true))
      relationshipUpdated(relationship)
    } catch {
      print("Error while following: \(error.localizedDescription)")
    }
    isUpdating = false
  }

  func unfollow() async {
    guard let client else { return }
    isUpdating = true
    do {
      relationship = try await client.post(endpoint: Accounts.unfollow(id: accountId))
      relationshipUpdated(relationship)
    } catch {
      print("Error while unfollowing: \(error.localizedDescription)")
    }
    isUpdating = false
  }

  func toggleNotify() async {
    guard let client else { return }
    do {
      relationship = try await client.post(endpoint: Accounts.follow(id: accountId,
                                                                     notify: !relationship.notifying,
                                                                     reblogs: relationship.showingReblogs))
      relationshipUpdated(relationship)
    } catch {
      print("Error while following: \(error.localizedDescription)")
    }
  }

  func toggleReboosts() async {
    guard let client else { return }
    do {
      relationship = try await client.post(endpoint: Accounts.follow(id: accountId,
                                                                     notify: relationship.notifying,
                                                                     reblogs: !relationship.showingReblogs))
      relationshipUpdated(relationship)
    } catch {
      print("Error while switching reboosts: \(error.localizedDescription)")
    }
  }
}

public struct FollowButton: View {
  @Environment(Client.self) private var client
  @State private var viewModel: FollowButtonViewModel

  public init(viewModel: FollowButtonViewModel) {
    _viewModel = .init(initialValue: viewModel)
  }

  public var body: some View {
    VStack(alignment: .trailing) {
      Button {
        Task {
          if viewModel.relationship.following {
            await viewModel.unfollow()
          } else {
            await viewModel.follow()
          }
        }
      } label: {
        if viewModel.relationship.requested == true {
          Text("account.follow.requested")
        } else {
          Text(viewModel.relationship.following ? "account.follow.following" : "account.follow.follow")
            .accessibilityLabel("account.follow.following")
            .accessibilityValue(viewModel.relationship.following ? "accessibility.general.toggle.on" : "accessibility.general.toggle.off")
        }
      }
      if viewModel.relationship.following,
         viewModel.shouldDisplayNotify
      {
        HStack {
          Button {
            Task {
              await viewModel.toggleNotify()
            }
          } label: {
            Image(systemName: viewModel.relationship.notifying ? "bell.fill" : "bell")
          }
          .accessibilityLabel("accessibility.tabs.profile.user-notifications.label")
          .accessibilityValue(viewModel.relationship.notifying ? "accessibility.general.toggle.on" : "accessibility.general.toggle.off")
          Button {
            Task {
              await viewModel.toggleReboosts()
            }
          } label: {
            Image(viewModel.relationship.showingReblogs ? "Rocket.Fill" : "Rocket")
          }
          .accessibilityLabel("accessibility.tabs.profile.user-reblogs.label")
          .accessibilityValue(viewModel.relationship.showingReblogs ? "accessibility.general.toggle.on" : "accessibility.general.toggle.off")
        }
      }
    }
    .buttonStyle(.bordered)
    .disabled(viewModel.isUpdating)
    .onAppear {
      viewModel.client = client
    }
  }
}
