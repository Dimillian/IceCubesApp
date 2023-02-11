import Foundation
import Models
import Network

@MainActor
public class CurrentInstance: ObservableObject {
  @Published public private(set) var instance: Instance?

  private var client: Client?

  public static let shared = CurrentInstance()

  public var isFiltersSupported: Bool {
    instance?.version.hasPrefix("4") == true
  }

  public var isEditSupported: Bool {
    instance?.version.hasPrefix("4") == true
  }
    
  public var isEditAltTextSupported: Bool {
    instance?.version.hasPrefix("4.1") == true
  }

  private init() {}

  public func setClient(client: Client) {
    self.client = client
  }

  public func fetchCurrentInstance() async {
    guard let client = client else { return }
    instance = try? await client.get(endpoint: Instances.instance)
  }
}
