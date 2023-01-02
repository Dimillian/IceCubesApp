import Foundation
import Models
import Network

@MainActor
public class CurrentAccount: ObservableObject {
  @Published public private(set) var account: Account?
  @Published public private(set) var lists: [List] = []
  
  private var client: Client?
  
  public init() {
    
  }
  
  public func setClient(client: Client) {
    self.client = client
    Task {
      await fetchCurrentAccount()
      await fetchLists()
    }
  }
  
  public func fetchCurrentAccount() async {
    guard let client = client, client.isAuth else {
      account = nil
      return
    }
    Task {
      account = try? await client.get(endpoint: Accounts.verifyCredentials)
    }
  }
  
  public func fetchLists() async {
    guard let client, client.isAuth else { return }
    do {
      lists = try await client.get(endpoint: Lists.lists)
    } catch {
      lists = []
    }
  }
  
  public func createList(title: String) async {
    guard let client else { return }
    do {
      let list: Models.List = try await client.post(endpoint: Lists.createList(title: title))
      lists.append(list)
    } catch { }
  }
  
  
  public func deleteList(list: Models.List) async {
    guard let client else { return }
    lists.removeAll(where: { $0.id == list.id })
    let response = try? await client.delete(endpoint: Lists.list(id: list.id))
    if response?.statusCode != 200 {
      lists.append(list)
    }
  }
}
