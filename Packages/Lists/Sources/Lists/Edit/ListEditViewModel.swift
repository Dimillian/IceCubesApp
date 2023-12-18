import Combine
import Env
import Models
import Network
import Observation
import SwiftUI

@MainActor
@Observable public class ListEditViewModel {
  var list: Models.List

  var client: Client?

  var isLoadingAccounts: Bool = true
  var accounts: [Account] = []

  var title: String
  var repliesPolicy: Models.List.RepliesPolicy
  var isExclusive: Bool

  var isUpdating: Bool = false

  var searchUserQuery: String = ""
  var searchedAccounts: [Account] = []
  var searchedRelationships: [String: Relationship] = [:]
  var isSearching: Bool = false

  init(list: Models.List) {
    self.list = list
    title = list.title
    repliesPolicy = list.repliesPolicy ?? .list
    isExclusive = list.exclusive ?? false
  }

  func fetchAccounts() async {
    guard let client else { return }
    isLoadingAccounts = true
    do {
      accounts = try await client.get(endpoint: Lists.accounts(listId: list.id))
      isLoadingAccounts = false
    } catch {
      isLoadingAccounts = false
    }
  }

  func update() async {
    guard let client else { return }
    do {
      isUpdating = true
      let list: Models.List = try await client.put(endpoint:
        Lists.updateList(id: list.id,
                         title: title,
                         repliesPolicy: repliesPolicy,
                         exclusive: isExclusive))
      self.list = list
      title = list.title
      repliesPolicy = list.repliesPolicy ?? .list
      isExclusive = list.exclusive ?? false
      isUpdating = false
      await CurrentAccount.shared.fetchLists()
    } catch {
      isUpdating = false
    }
  }

  func add(account: Account) async {
    guard let client else { return }
    do {
      isUpdating = true
      let response = try await client.post(endpoint: Lists.updateAccounts(listId: list.id, accounts: [account.id]))
      if response?.statusCode == 200 {
        accounts.append(account)
      }
      isUpdating = false
    } catch {
      isUpdating = false
    }
  }

  func delete(account: Account) async {
    guard let client else { return }
    do {
      isUpdating = true
      let response = try await client.delete(endpoint: Lists.updateAccounts(listId: list.id, accounts: [account.id]))
      if response?.statusCode == 200 {
        accounts.removeAll(where: { $0.id == account.id })
      }
      isUpdating = false
    } catch {
      isUpdating = false
    }
  }

  func searchUsers() async {
    guard let client, !searchUserQuery.isEmpty else { return }
    do {
      isSearching = true
      let results: SearchResults = try await client.get(endpoint: Search.search(query: searchUserQuery,
                                                                                type: nil,
                                                                                offset: nil,
                                                                                following: nil),
                                                        forceVersion: .v2)
      let relationships: [Relationship] =
        try await client.get(endpoint: Accounts.relationships(ids: results.accounts.map(\.id)))
      searchedRelationships = relationships.reduce(into: [String: Relationship]()) {
        $0[$1.id] = $1
      }
      searchedAccounts = results.accounts
      isSearching = false
    } catch {}
  }
}

extension Models.List.RepliesPolicy {
  var title: LocalizedStringKey {
    switch self {
    case .followed:
      "list.repliesPolicy.followed"
    case .list:
      "list.repliesPolicy.list"
    case .none:
      "list.repliesPolicy.none"
    }
  }
}
