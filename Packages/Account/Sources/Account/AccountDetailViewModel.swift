import Env
import Models
import Network
import Observation
import StatusKit
import SwiftUI

@MainActor
@Observable class AccountDetailViewModel {
  let accountId: String
  var client: Client?
  var isCurrentUser: Bool = false

  enum AccountState {
    case loading
    case data(account: Account)
    case error(error: Error)
  }

  var accountState: AccountState = .loading
  var account: Account?
  var relationship: Relationship?
  var featuredTags: [FeaturedTag] = []
  var fields: [Account.Field] = []
  var familiarFollowers: [Account] = []
  var followButtonViewModel: FollowButtonViewModel?
  var translation: Translation?
  var isLoadingTranslation = false

  /// When coming from a URL like a mention tap in a status.
  init(accountId: String) {
    self.accountId = accountId
    isCurrentUser = false
  }

  /// When the account is already fetched by the parent caller.
  init(account: Account) {
    accountId = account.id
    self.account = account
    accountState = .data(account: account)
  }

  struct AccountData {
    let account: Account
    let featuredTags: [FeaturedTag]
    let relationships: [Relationship]
  }

  func fetchAccount() async {
    guard let client else { return }
    do {
      let data = try await fetchAccountData(accountId: accountId, client: client)

      accountState = .data(account: data.account)
      account = data.account
      fields = data.account.fields
      featuredTags = data.featuredTags
      featuredTags.sort { $0.statusesCountInt > $1.statusesCountInt }
      relationship = data.relationships.first
      if let relationship {
        if let followButtonViewModel {
          followButtonViewModel.relationship = relationship
        } else {
          followButtonViewModel = .init(
            client: client,
            accountId: accountId,
            relationship: relationship,
            shouldDisplayNotify: true,
            relationshipUpdated: { [weak self] relationship in
              self?.relationship = relationship
            })
        }
      }
    } catch {
      if let account {
        accountState = .data(account: account)
      } else {
        accountState = .error(error: error)
      }
    }
  }

  private func fetchAccountData(accountId: String, client: Client) async throws -> AccountData {
    async let account: Account = client.get(endpoint: Accounts.accounts(id: accountId))
    async let featuredTags: [FeaturedTag] = client.get(
      endpoint: Accounts.featuredTags(id: accountId))
    if client.isAuth, !isCurrentUser {
      async let relationships: [Relationship] = client.get(
        endpoint: Accounts.relationships(ids: [accountId]))
      do {
        return try await .init(
          account: account,
          featuredTags: featuredTags,
          relationships: relationships)
      } catch {
        return try await .init(
          account: account,
          featuredTags: [],
          relationships: relationships)
      }
    }
    return try await .init(
      account: account,
      featuredTags: featuredTags,
      relationships: [])
  }

  func fetchFamilliarFollowers() async {
    let familiarFollowers: [FamiliarAccounts]? = try? await client?.get(
      endpoint: Accounts.familiarFollowers(withAccount: accountId))
    self.familiarFollowers = familiarFollowers?.first?.accounts ?? []
  }
}
