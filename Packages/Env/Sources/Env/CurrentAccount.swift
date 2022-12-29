import Foundation
import Models
import Network

@MainActor
public class CurrentAccount: ObservableObject {
  @Published public private(set) var account: Account?
  
  private var client: Client?
  
  public init() {
    
  }
  
  public func setClient(client: Client) {
    self.client = client
    Task {
      await fetchCurrentAccount()
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
}
