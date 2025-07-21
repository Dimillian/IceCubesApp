import Combine
import Foundation
import Models
import Network
import Observation

@MainActor
@Observable public class CurrentInstance {
  public private(set) var instance: Instance?
  public private(set) var nodeInfo: NodeInfo?

  private var client: Client?

  public static let shared = CurrentInstance()

  private var version: Float {
    guard let stringVersion = instance?.version else { return 0 }
    
    // Parse version based on detected server type
    if isGoToSocial {
      // Parse GoToSocial versions (0.x.y format)
      let versionPart = stringVersion.split(separator: "+").first ?? stringVersion[...]
      let components = String(versionPart).split(separator: ".").compactMap { component in
        Float(String(component.prefix(while: { $0.isNumber })))
      }
      
      if components.count >= 2 {
        // Convert 0.19.1 to 0.191 for comparison
        let major = components[0]
        let minor = components[1]
        let patch = components.count > 2 ? components[2] : 0
        return major + (minor / 100.0) + (patch / 10000.0)
      }
    }
    
    // Handle Mastodon versions (existing logic)
    if stringVersion.utf8.count > 2 {
      return Float(stringVersion.prefix(3)) ?? 0
    } else {
      return Float(stringVersion.prefix(1)) ?? 0
    }
  }

  public var isFiltersSupported: Bool {
    guard let stringVersion = instance?.version else { return false }
    
    if isGoToSocial {
      // GoToSocial filters since 0.11.0
      return version >= 0.11
    }
    
    // Mastodon filters since 4.0
    return version >= 4
  }

  private var isGoToSocial: Bool {
    // Use NodeInfo as single source of truth when available
    if let nodeInfo = nodeInfo {
      return nodeInfo.software.name.lowercased() == "gotosocial"
    }
    
    // When NodeInfo unavailable, always default to Mastodon (safer)
    return false
  }

  public var isEditSupported: Bool {
    guard let stringVersion = instance?.version else { return false }
    
    if isGoToSocial {
      // GoToSocial edit support since 0.8.0
      return version >= 0.08
    }
    
    // Mastodon edit support since 3.5.0
    return version >= 3.5
  }

  public var isEditAltTextSupported: Bool {
    guard let stringVersion = instance?.version else { return false }
    
    if isGoToSocial {
      // GoToSocial supports alt text editing
      return version >= 0.08
    }
    
    // Mastodon alt text editing since 4.1
    return version >= 4.1
  }

  public var isNotificationsFilterSupported: Bool {
    guard let stringVersion = instance?.version else { return false }
    
    if isGoToSocial {
      // GoToSocial notifications - conservative estimate
      return version >= 0.12
    }
    
    // Mastodon notification filters since 4.3
    return version >= 4.3
  }

  public var isLinkTimelineSupported: Bool {
    guard let stringVersion = instance?.version else { return false }
    
    if isGoToSocial {
      // GoToSocial may not support link timelines - disable for now
      return false
    }
    
    // Mastodon link timeline since 4.3
    return version >= 4.3
  }

  private init() {}

  public func setClient(client: Client) {
    self.client = client
  }

  public func fetchCurrentInstance() async {
    guard let client else { return }
    
    // Fetch NodeInfo first (single source of truth for server identification)
    // Follow NodeInfo 2.0 specification: discover via .well-known/nodeinfo
    do {
      let discovery: NodeInfoDiscovery = try await client.get(endpoint: NodeInfo.wellKnownNodeInfo)
      if let nodeInfoURL = discovery.nodeInfo20URL {
        // Extract path from full URL for the endpoint
        if let url = URL(string: nodeInfoURL) {
          let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
          nodeInfo = try await client.get(endpoint: NodeInfo.nodeInfo(url: path))
        }
      }
    } catch {
      // NodeInfo not available, will fallback to version-based detection
      nodeInfo = nil
    }
    
    // Fetch instance info (simplified - no header extraction needed)
    instance = try? await client.get(endpoint: Instances.instance)
  }
}
