import Foundation
import Models
import Network
import SwiftUI

@MainActor
public class UserPreferences: ObservableObject {
  public static let sharedDefault = UserDefaults(suiteName: "group.icecubesapps")
  public static let shared = UserPreferences()

  private var client: Client?

  @AppStorage("remote_local_timeline") public var remoteLocalTimelines: [String] = []
  @AppStorage("preferred_browser") public var preferredBrowser: PreferredBrowser = .inAppSafari
  @AppStorage("draft_posts") public var draftsPosts: [String] = []
  @AppStorage("font_size_scale") public var fontSizeScale: Double = 1
  @AppStorage("show_translate_button_inline") public var showTranslateButton: Bool = true
  @AppStorage("is_open_ai_enabled") public var isOpenAIEnabled: Bool = true
  
  @AppStorage("use_instance_content_settings") public var useInstanceContentSettings: Bool = true
  @AppStorage("app_auto_expand_spoilers") public var appAutoExpandSpoilers = false
  @AppStorage("app_auto_expand_media") public var appAutoExpandMedia:ServerPreferences.AutoExpandMedia = .hideSensitive

  
  public var autoExpandSpoilers: Bool {
    get {
      if useInstanceContentSettings {
        if serverPreferences?.autoExpandSpoilers == true {
          return true
        }
        else {
          return false;
        }
      }
      else {
        return appAutoExpandSpoilers
      }
    }
  }
  
  public var autoExpandMedia: ServerPreferences.AutoExpandMedia {
    get {
      if useInstanceContentSettings {
        if let auto = serverPreferences?.autoExpandMedia {
          return auto
        }
        else {
          return ServerPreferences.AutoExpandMedia.hideSensitive
        }
      }
      else {
        return appAutoExpandMedia
      }
    }
  }
  

  public var pushNotificationsCount: Int {
    get {
      Self.sharedDefault?.integer(forKey: "push_notifications_count") ?? 0
    }
    set {
      Self.sharedDefault?.set(newValue, forKey: "push_notifications_count")
    }
  }

  @Published public var serverPreferences: ServerPreferences?

  private init() {}

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
