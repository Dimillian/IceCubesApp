import Foundation
import SwiftUI
import Models
import Network

@MainActor
public class FollowButtonViewModel: ObservableObject {
  var client: Client?
  
  public let accountId: String
  public let shouldDisplayNotify: Bool
  @Published private(set) public var relationship: Relationshionship
  @Published private(set) public var isUpdating: Bool = false
  
  public init(accountId: String, relationship: Relationshionship, shouldDisplayNotify: Bool) {
    self.accountId = accountId
    self.relationship = relationship
    self.shouldDisplayNotify = shouldDisplayNotify
  }
  
  func follow() async {
    guard let client else { return }
    isUpdating = true
    do {
      relationship = try await client.post(endpoint: Accounts.follow(id: accountId, notify: false))
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
    } catch {
      print("Error while unfollowing: \(error.localizedDescription)")
    }
    isUpdating = false
  }
  
  func toggleNotify() async {
    guard let client else { return }
    do {
      relationship = try await client.post(endpoint: Accounts.follow(id: accountId, notify: !relationship.notifying))
    } catch {
      print("Error while following: \(error.localizedDescription)")
    }
  }
}

public struct FollowButton: View {
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel: FollowButtonViewModel
  
  public init(viewModel: FollowButtonViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }
  
  public var body: some View {
    HStack {
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
          Text("Requested")
        } else {
          Text(viewModel.relationship.following ? "Following" : "Follow")
        }
      }
      .buttonStyle(.bordered)
      .disabled(viewModel.isUpdating)
      if viewModel.relationship.following, viewModel.shouldDisplayNotify {
        Button {
          Task {
            await viewModel.toggleNotify()
          }
        } label: {
          Image(systemName: viewModel.relationship.notifying ? "bell.fill" : "bell")
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.isUpdating)
      }
    }
    .onAppear {
      viewModel.client = client
    }
  }
}
