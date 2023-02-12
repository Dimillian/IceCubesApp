import Foundation
import Models
import Network
import SwiftUI

@MainActor
public class UserPreferences: ObservableObject {
  public static let sharedDefault = UserDefaults(suiteName: "group.com.thomasricouard.IceCubesApp")
  public static let shared = UserPreferences()

  private var client: Client?

  @AppStorage("remote_local_timeline") public var remoteLocalTimelines: [String] = []
  @AppStorage("preferred_browser") public var preferredBrowser: PreferredBrowser = .inAppSafari
  @AppStorage("draft_posts") public var draftsPosts: [String] = []
  @AppStorage("font_size_scale") public var fontSizeScale: Double = 1
  @AppStorage("show_translate_button_inline") public var showTranslateButton: Bool = true
  @AppStorage("is_open_ai_enabled") public var isOpenAIEnabled: Bool = true

  @AppStorage("recently_used_languages") public var recentlyUsedLanguages: [String] = []
  @AppStorage("social_keyboard_composer") public var isSocialKeyboardEnabled: Bool = true

  @AppStorage("use_instance_content_settings") public var useInstanceContentSettings: Bool = true
  @AppStorage("app_auto_expand_spoilers") public var appAutoExpandSpoilers = false
  @AppStorage("app_auto_expand_media") public var appAutoExpandMedia: ServerPreferences.AutoExpandMedia = .hideSensitive
  @AppStorage("app_default_post_visibility") public var appDefaultPostVisibility: Models.Visibility = .pub
  @AppStorage("app_default_posts_sensitive") public var appDefaultPostsSensitive = false
  @AppStorage("autoplay_video") public var autoPlayVideo = true
  @AppStorage("chosen_font") public private(set) var chosenFontData: Data?

  @AppStorage("suppress_dupe_reblogs") public var suppressDupeReblogs: Bool = false

  @AppStorage("inAppBrowserReaderView") public var inAppBrowserReaderView = false

  @AppStorage("haptic_tab") public var hapticTabSelectionEnabled = true
  @AppStorage("haptic_timeline") public var hapticTimelineEnabled = true
  @AppStorage("haptic_button_press") public var hapticButtonPressEnabled = true

  @AppStorage("show_tab_label_iphone") public var showiPhoneTabLabel = true

  @AppStorage("show_second_column_ipad") public var showiPadSecondaryColumn = true

  @AppStorage("swipeactions-status-trailing-right") public var swipeActionsStatusTrailingRight = StatusAction.favorite
  @AppStorage("swipeactions-status-trailing-left") public var swipeActionsStatusTrailingLeft = StatusAction.boost
  @AppStorage("swipeactions-status-leading-left") public var swipeActionsStatusLeadingLeft = StatusAction.reply
  @AppStorage("swipeactions-status-leading-right") public var swipeActionsStatusLeadingRight = StatusAction.none

  public var postVisibility: Models.Visibility {
    if useInstanceContentSettings {
      return serverPreferences?.postVisibility ?? .pub
    } else {
      return appDefaultPostVisibility
    }
  }

  public var postIsSensitive: Bool {
    if useInstanceContentSettings {
      return serverPreferences?.postIsSensitive ?? false
    } else {
      return appDefaultPostsSensitive
    }
  }

  public var autoExpandSpoilers: Bool {
    if useInstanceContentSettings {
      return serverPreferences?.autoExpandSpoilers ?? true
    } else {
      return appAutoExpandSpoilers
    }
  }

  public var autoExpandMedia: ServerPreferences.AutoExpandMedia {
    if useInstanceContentSettings {
      return serverPreferences?.autoExpandMedia ?? .hideSensitive
    } else {
      return appAutoExpandMedia
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

  public var chosenFont: UIFont? {
    get {
      guard let chosenFontData,
            let font = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIFont.self, from: chosenFontData) else { return nil }

      return font
    }
    set {
      if let font = newValue,
         let data = try? NSKeyedArchiver.archivedData(withRootObject: font, requiringSecureCoding: false)
      {
        chosenFontData = data
      } else {
        chosenFontData = nil
      }
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

  public func markLanguageAsSelected(isoCode: String) {
    var copy = recentlyUsedLanguages
    if let index = copy.firstIndex(of: isoCode) {
      copy.remove(at: index)
    }
    copy.insert(isoCode, at: 0)
    recentlyUsedLanguages = Array(copy.prefix(3))
  }
}
