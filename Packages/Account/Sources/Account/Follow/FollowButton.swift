import Foundation
import Models
import Network
import SwiftUI

@MainActor
public class FollowButtonViewModel: ObservableObject {
  var client: Client?

  public let accountId: String
  public let relationshipUpdated: (Relationship) -> Void
  @Published public private(set) var relationship: Relationship
  @Published public private(set) var isUpdating: Bool = false

  public init(accountId: String,
              relationship: Relationship,
              relationshipUpdated: @escaping ((Relationship) -> Void))
  {
    self.accountId = accountId
    self.relationship = relationship
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
}

public struct FollowButton: View {
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel: FollowButtonViewModel

  public init(viewModel: FollowButtonViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }

  public var body: some View {
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
      }
    }
    .buttonStyle(.bordered)
    .disabled(viewModel.isUpdating)
    .onAppear {
      viewModel.client = client
    }
  }
}
