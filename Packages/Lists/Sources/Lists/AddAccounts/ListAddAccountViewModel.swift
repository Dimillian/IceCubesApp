import Models
import Network
import Observation
import SwiftUI

@MainActor
@Observable class ListAddAccountViewModel {
  let account: Account

  var inLists: [Models.List] = []
  var isLoadingInfo: Bool = true

  var client: Client?

  init(account: Account) {
    self.account = account
  }

  func fetchInfo() async {
    guard let client else { return }
    isLoadingInfo = true
    do {
      inLists = try await client.get(endpoint: Accounts.lists(id: account.id))
      isLoadingInfo = false
    } catch {
      withAnimation {
        isLoadingInfo = false
      }
    }
  }

  func addToList(list: Models.List) async {
    guard let client else { return }
    let response = try? await client.post(endpoint: Lists.updateAccounts(listId: list.id, accounts: [account.id]))
    if response?.statusCode == 200 {
      inLists.append(list)
    }
  }

  func removeFromList(list: Models.List) async {
    guard let client else { return }
    let response = try? await client.delete(endpoint: Lists.updateAccounts(listId: list.id, accounts: [account.id]))
    if response?.statusCode == 200 {
      inLists.removeAll(where: { $0.id == list.id })
    }
  }
}
