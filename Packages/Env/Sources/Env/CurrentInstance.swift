import Foundation
import Models
import Network

@MainActor
public class CurrentInstance: ObservableObject {
  @Published public private(set) var instance: Instance?
  
  private var client: Client?
  
  public init() {
    
  }
  
  public func setClient(client: Client) {
    self.client = client
    Task {
      await fetchCurrentInstance()
    }
  }
  
  public func fetchCurrentInstance() async {
    guard let client = client else { return }
    Task {
      instance = try? await client.get(endpoint: Instances.instance)
    }
  }
}
