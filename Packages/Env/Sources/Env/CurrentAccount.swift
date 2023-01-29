import Foundation
import Models
import Network

@MainActor
public class CurrentAccount: ObservableObject {
  @Published public private(set) var account: Account?
  @Published public private(set) var lists: [List] = []
  @Published public private(set) var tags: [Tag] = []
  @Published public private(set) var followRequests: [Account] = []
  @Published public private(set) var isUpdating: Bool = false

  private var client: Client?

  public static let shared = CurrentAccount()

  private init() {}

  public func setClient(client: Client) {
    self.client = client
    guard client.isAuth else { return }
    Task(priority: .userInitiated) {
      await fetchUserData()
    }
  }

  private func fetchUserData() async {
    await withTaskGroup(of: Void.self) { group in
      group.addTask { await self.fetchConnections() }
      group.addTask { await self.fetchCurrentAccount() }
      group.addTask { await self.fetchLists() }
      group.addTask { await self.fetchFollowedTags() }
      group.addTask { await self.fetchFollowerRequests() }
    }
  }

  public func fetchConnections() async {
    guard let client = client else { return }
    do {
      let connections: [String] = try await client.get(endpoint: Instances.peers)
      client.addConnections(connections)
    } catch {}
  }

  public func fetchCurrentAccount() async {
    guard let client = client, client.isAuth else {
      account = nil
      return
    }
    account = try? await client.get(endpoint: Accounts.verifyCredentials)
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

  public func createList(title: String) async {
    guard let client else { return }
    do {
      let list: Models.List = try await client.post(endpoint: Lists.createList(title: title))
      lists.append(list)
    } catch {}
  }

  public func deleteList(list: Models.List) async {
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
      isUpdating = true
      defer {
        isUpdating = false
      }
      _ = try await client.post(endpoint: FollowRequests.accept(id: id))
      await fetchFollowerRequests()
    } catch {}
  }

  public func rejectFollowerRequest(id: String) async {
    guard let client else { return }
    do {
      isUpdating = true
      defer {
        isUpdating = false
      }
      _ = try await client.post(endpoint: FollowRequests.reject(id: id))
      await fetchFollowerRequests()
    } catch {}
  }
}
