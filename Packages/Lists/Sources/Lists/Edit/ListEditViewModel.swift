import Combine
import Models
import Network
import Observation
import SwiftUI
import Env

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

  init(list: Models.List) {
    self.list = list
    self.title = list.title
    self.repliesPolicy = list.repliesPolicy
    self.isExclusive = list.exclusive
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
                                                                     exclusive: isExclusive ))
      self.list = list
      self.title = list.title
      self.repliesPolicy = list.repliesPolicy
      self.isExclusive = list.exclusive
      self.isUpdating = false
      await CurrentAccount.shared.fetchLists()
    } catch {
      isUpdating = false
    }
  }
  
  func delete(account: Account) async {
    guard let client else { return }
    do {
      let response = try await client.delete(endpoint: Lists.updateAccounts(listId: list.id, accounts: [account.id]))
      if response?.statusCode == 200 {
        accounts.removeAll(where: { $0.id == account.id })
      }
    } catch {}
  }
}

extension Models.List.RepliesPolicy {
  var title: LocalizedStringKey {
    switch self {
    case .followed:
      return "list.repliesPolicy.followed"
    case .list:
      return "list.repliesPolicy.list"
    case .none:
      return "list.repliesPolicy.none"
    }
  }
}
