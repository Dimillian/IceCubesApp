import Models
import Network
import Observation
import OSLog
import SwiftUI

public enum AccountsListMode {
  case following(accountId: String), followers(accountId: String)
  case favoritedBy(statusId: String), rebloggedBy(statusId: String)
  case accountsList(accounts: [Account])

  var title: LocalizedStringKey {
    switch self {
    case .following:
      "account.following"
    case .followers:
      "account.followers"
    case .favoritedBy:
      "account.favorited-by"
    case .rebloggedBy:
      "account.boosted-by"
    case .accountsList:
      ""
    }
  }
}

@MainActor
@Observable class AccountsListViewModel {
  var client: Client?

  let mode: AccountsListMode

  public enum State {
    public enum PagingState {
      case hasNextPage, none
    }

    case loading
    case display(accounts: [Account],
                 relationships: [Relationship],
                 nextPageState: PagingState)
    case error(error: Error)
  }

  private var accounts: [Account] = []
  private var relationships: [Relationship] = []

  var state = State.loading
  var totalCount: Int?
  var accountId: String?

  var searchQuery: String = ""

  private var nextPageId: String?

  init(mode: AccountsListMode) {
    self.mode = mode
  }

  func fetch() async {
    guard let client else { return }
    do {
      state = .loading
      let link: LinkHandler?
      switch mode {
      case let .followers(accountId):
        let account: Account = try await client.get(endpoint: Accounts.accounts(id: accountId))
        totalCount = account.followersCount
        (accounts, link) = try await client.getWithLink(endpoint: Accounts.followers(id: accountId,
                                                                                     maxId: nil))
      case let .following(accountId):
        self.accountId = accountId
        let account: Account = try await client.get(endpoint: Accounts.accounts(id: accountId))
        totalCount = account.followingCount
        (accounts, link) = try await client.getWithLink(endpoint: Accounts.following(id: accountId,
                                                                                     maxId: nil))
      case let .rebloggedBy(statusId):
        (accounts, link) = try await client.getWithLink(endpoint: Statuses.rebloggedBy(id: statusId,
                                                                                       maxId: nil))
      case let .favoritedBy(statusId):
        (accounts, link) = try await client.getWithLink(endpoint: Statuses.favoritedBy(id: statusId,
                                                                                       maxId: nil))
      case let .accountsList(accounts):
        self.accounts = accounts
        link = nil
      }
      nextPageId = link?.maxId
      relationships = try await client.get(endpoint:
        Accounts.relationships(ids: accounts.map(\.id)))
      state = .display(accounts: accounts,
                       relationships: relationships,
                       nextPageState: link?.maxId != nil ? .hasNextPage : .none)
    } catch {}
  }

  func fetchNextPage() async throws {
    guard let client, let nextPageId else { return }
    let newAccounts: [Account]
    let link: LinkHandler?
    switch mode {
    case let .followers(accountId):
      (newAccounts, link) = try await client.getWithLink(endpoint: Accounts.followers(id: accountId,
                                                                                      maxId: nextPageId))
    case let .following(accountId):
      (newAccounts, link) = try await client.getWithLink(endpoint: Accounts.following(id: accountId,
                                                                                      maxId: nextPageId))
    case let .rebloggedBy(statusId):
      (newAccounts, link) = try await client.getWithLink(endpoint: Statuses.rebloggedBy(id: statusId,
                                                                                        maxId: nextPageId))
    case let .favoritedBy(statusId):
      (newAccounts, link) = try await client.getWithLink(endpoint: Statuses.favoritedBy(id: statusId,
                                                                                        maxId: nextPageId))
    case .accountsList:
      newAccounts = []
      link = nil
    }
    accounts.append(contentsOf: newAccounts)
    let newRelationships: [Relationship] =
      try await client.get(endpoint: Accounts.relationships(ids: newAccounts.map(\.id)))

    relationships.append(contentsOf: newRelationships)
    self.nextPageId = link?.maxId
    state = .display(accounts: accounts,
                     relationships: relationships,
                     nextPageState: link?.maxId != nil ? .hasNextPage : .none)
  }

  func search() async {
    guard let client, !searchQuery.isEmpty else { return }
    do {
      state = .loading
      try await Task.sleep(for: .milliseconds(250))
      var results: SearchResults = try await client.get(endpoint: Search.search(query: searchQuery,
                                                                                type: "accounts",
                                                                                offset: nil,
                                                                                following: true),
                                                        forceVersion: .v2)
      let relationships: [Relationship] =
        try await client.get(endpoint: Accounts.relationships(ids: results.accounts.map(\.id)))
      results.relationships = relationships
      withAnimation {
        state = .display(accounts: results.accounts,
                         relationships: relationships,
                         nextPageState: .none)
      }
    } catch {}
  }
}
