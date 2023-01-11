import SwiftUI
import Foundation
import Models
import Network

@MainActor
public class UserPreferences: ObservableObject {
  private static let sharedDefault = UserDefaults.init(suiteName: "group.icecubesapps")
  
  private var client: Client?
  
  @AppStorage("remote_local_timeline") public var remoteLocalTimelines: [String] = []
  @AppStorage("preferred_browser") public var preferredBrowser: PreferredBrowser = .inAppSafari
  @AppStorage("draft_posts") public var draftsPosts: [String] = []
  
  public var pushNotificationsCount: Int {
    get {
      Self.sharedDefault?.integer(forKey: "push_notifications_count") ?? 0
    }
    set {
      Self.sharedDefault?.set(newValue, forKey: "push_notifications_count")
    }
  }
  
  @Published public var serverPreferences: ServerPreferences?
  
  public init() { }
  
  public func setClient(client: Client) {
    self.client = client
    Task {
      await refreshServerPreferences()
    }
  }
  
  public func refreshServerPreferences() async {
    guard let client, client.isAuth else { return }
    serverPreferences = try? await client.get(endpoint: Accounts.preferences)
  }
}
