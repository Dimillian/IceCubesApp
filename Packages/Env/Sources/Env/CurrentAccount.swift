import Combine
import Foundation
import Models
import NetworkClient
import Observation

@MainActor
@Observable public class CurrentAccount {
  private static var accountsCache: [String: Account] = [:]

  public private(set) var account: Account?
  public private(set) var lists: [List] = []
  public private(set) var tags: [Tag] = []
  public private(set) var followRequests: [Account] = []
  public private(set) var isUpdating: Bool = false
  public private(set) var updatingFollowRequestAccountIds = Set<String>()
  public private(set) var isLoadingAccount: Bool = false

  private var client: MastodonClient?

  public static let shared = CurrentAccount()

  public var sortedLists: [List] {
    lists.sorted { $0.title.lowercased() < $1.title.lowercased() }
  }

  public var sortedTags: [Tag] {
    tags.sorted { $0.name.lowercased() < $1.name.lowercased() }
  }

  private init() {}

  public func setClient(client: MastodonClient) {
    self.client = client
    guard client.isAuth else { return }
    Task(priority: .userInitiated) {
      await fetchUserData()
    }
  }

  private func fetchUserData() async {
    await withTaskGroup(of: Void.self) { group in
      group.addTask { await self.fetchCurrentAccount() }
      group.addTask { await self.fetchConnections() }
      group.addTask { await self.fetchLists() }
      group.addTask { await self.fetchFollowedTags() }
      group.addTask { await self.fetchFollowerRequests() }
    }
  }

  public func fetchConnections() async {
    guard let client else { return }
    do {
      let connections: [String] = try await client.get(endpoint: Instances.peers)
      client.addConnections(connections)
    } catch {}
  }

  public func fetchCurrentAccount() async {
    guard let client, client.isAuth else {
      account = nil
      return
    }
    account = Self.accountsCache[client.id]
    if account == nil {
      isLoadingAccount = true
    }
    account = try? await client.get(endpoint: Accounts.verifyCredentials)
    isLoadingAccount = false
    Self.accountsCache[client.id] = account
  }

  public func fetchLists() async {
    guard let client, client.isAuth else { return }
    do {
      lists = try await client.get(endpoint: Lists.lists)
    } catch {
      lists = []
    }
  }

  public func fetchFollowedTags() async {
    guard let client, client.isAuth else { return }
    do {
      tags = try await client.get(endpoint: Accounts.followedTags)
    } catch {
      tags = []
    }
  }

  public func deleteList(_ list: Models.List) async {
    guard let client else { return }
    lists.removeAll(where: { $0.id == list.id })
    let response = try? await client.delete(endpoint: Lists.list(id: list.id))
    if response?.statusCode != 200 {
      lists.append(list)
    }
  }

  public func followTag(id: String) async -> Tag? {
    guard let client else { return nil }
    do {
      let tag: Tag = try await client.post(endpoint: Tags.follow(id: id))
      tags.append(tag)
      return tag
    } catch {
      return nil
    }
  }

  public func unfollowTag(id: String) async -> Tag? {
    guard let client else { return nil }
    do {
      let tag: Tag = try await client.post(endpoint: Tags.unfollow(id: id))
      tags.removeAll { $0.id == tag.id }
      return tag
    } catch {
      return nil
    }
  }

  public func fetchFollowerRequests() async {
    guard let client else { return }
    do {
      followRequests = try await client.get(endpoint: FollowRequests.list)
    } catch {
      followRequests = []
    }
  }

  public func acceptFollowerRequest(id: String) async {
    guard let client else { return }
    do {
      updatingFollowRequestAccountIds.insert(id)
      defer {
        updatingFollowRequestAccountIds.remove(id)
      }
      _ = try await client.post(endpoint: FollowRequests.accept(id: id))
      await fetchFollowerRequests()
    } catch {}
  }

  public func rejectFollowerRequest(id: String) async {
    guard let client else { return }
    do {
      updatingFollowRequestAccountIds.insert(id)
      defer {
        updatingFollowRequestAccountIds.remove(id)
      }
      _ = try await client.post(endpoint: FollowRequests.reject(id: id))
      await fetchFollowerRequests()
    } catch {}
  }
}
