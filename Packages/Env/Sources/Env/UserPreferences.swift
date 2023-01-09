import SwiftUI
import Foundation

public class UserPreferences: ObservableObject {
  private static let sharedDefault = UserDefaults.init(suiteName: "group.icecubesapps")
  
  @AppStorage("remote_local_timeline") public var remoteLocalTimelines: [String] = []
  @AppStorage("preferred_browser") public var preferredBrowser: PreferredBrowser = .inAppSafari
  public var pushNotificationsCount: Int {
    get {
      Self.sharedDefault?.integer(forKey: "push_notifications_count") ?? 0
    }
    set {
      Self.sharedDefault?.set(newValue, forKey: "push_notifications_count")
    }
  }
  
  public init() { }
}
