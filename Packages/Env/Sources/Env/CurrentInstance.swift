import Foundation
import Models
import Network

@MainActor
public class CurrentInstance: ObservableObject {
  @Published public private(set) var instance: Instance?

  private var client: Client?

  public static let shared = CurrentInstance()

  private var version: InstanceVersion {
    let stringVersion = instance?.version ?? "0"
    return InstanceVersion(stringVersion)!
  }

  public var isFiltersSupported: Bool {
    version >= InstanceVersion("4")
  }

  public var isEditSupported: Bool {
    version >= InstanceVersion("4")
  }

  public var isEditAltTextSupported: Bool {
    version >= InstanceVersion("4.1")
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
