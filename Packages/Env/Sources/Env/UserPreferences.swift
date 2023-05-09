import Combine
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
  @AppStorage("tag_groups") public var tagGroups: [TagGroup] = []
  @AppStorage("preferred_browser") public var preferredBrowser: PreferredBrowser = .inAppSafari
  @AppStorage("draft_posts") public var draftsPosts: [String] = []
  @AppStorage("show_translate_button_inline") public var showTranslateButton: Bool = true
  @AppStorage("is_open_ai_enabled") public var isOpenAIEnabled: Bool = true

  @AppStorage("recently_used_languages") public var recentlyUsedLanguages: [String] = []
  @AppStorage("social_keyboard_composer") public var isSocialKeyboardEnabled: Bool = true

  @AppStorage("use_instance_content_settings") public var useInstanceContentSettings: Bool = true
  @AppStorage("app_auto_expand_spoilers") public var appAutoExpandSpoilers = false
  @AppStorage("app_auto_expand_media") public var appAutoExpandMedia: ServerPreferences.AutoExpandMedia = .hideSensitive
  @AppStorage("app_default_post_visibility") public var appDefaultPostVisibility: Models.Visibility = .pub
  @AppStorage("app_default_reply_visibility") public var appDefaultReplyVisibility: Models.Visibility = .pub
  @AppStorage("app_default_posts_sensitive") public var appDefaultPostsSensitive = false
  @AppStorage("autoplay_video") public var autoPlayVideo = true
  @AppStorage("always_use_deepl") public var alwaysUseDeepl = false
  @AppStorage("user_deepl_api_free") public var userDeeplAPIFree = true
  @AppStorage("auto_detect_post_language") public var autoDetectPostLanguage = true

  @AppStorage("suppress_dupe_reblogs") public var suppressDupeReblogs: Bool = false

  @AppStorage("show_replies") public var showReplies: Bool = true

  @AppStorage("inAppBrowserReaderView") public var inAppBrowserReaderView = false

  @AppStorage("haptic_tab") public var hapticTabSelectionEnabled = true
  @AppStorage("haptic_timeline") public var hapticTimelineEnabled = true
  @AppStorage("haptic_button_press") public var hapticButtonPressEnabled = true
  @AppStorage("sound_effect_enabled") public var soundEffectEnabled = true

  @AppStorage("show_tab_label_iphone") public var showiPhoneTabLabel = true
  @AppStorage("show_alt_text_for_media") public var showAltTextForMedia = true

  @AppStorage("show_second_column_ipad") public var showiPadSecondaryColumn = true

  @AppStorage("swipeactions-status-trailing-right") public var swipeActionsStatusTrailingRight = StatusAction.favorite
  @AppStorage("swipeactions-status-trailing-left") public var swipeActionsStatusTrailingLeft = StatusAction.boost
  @AppStorage("swipeactions-status-leading-left") public var swipeActionsStatusLeadingLeft = StatusAction.reply
  @AppStorage("swipeactions-status-leading-right") public var swipeActionsStatusLeadingRight = StatusAction.none
  @AppStorage("swipeactions-use-theme-color") public var swipeActionsUseThemeColor = false
  @AppStorage("swipeactions-icon-style") public var swipeActionsIconStyle: SwipeActionsIconStyle = .iconWithText

  @AppStorage("requested_review") public var requestedReview = false

  @AppStorage("collapse-long-posts") public var collapseLongPosts = true

  @AppStorage("share-button-behavior") public var shareButtonBehavior: PreferredShareButtonBehavior = .linkAndText

  public enum SwipeActionsIconStyle: String, CaseIterable {
    case iconWithText, iconOnly

    public var description: LocalizedStringKey {
      switch self {
      case .iconWithText:
        return "enum.swipeactions.icon-with-text"
      case .iconOnly:
        return "enum.swipeactions.icon-only"
      }
    }

    // Have to implement this manually here due to compiler not implicitly
    // inserting `nonisolated`, which leads to a warning:
    //
    //     Main actor-isolated static property 'allCases' cannot be used to
    //     satisfy nonisolated protocol requirement
    //
    public nonisolated static var allCases: [Self] {
      [.iconWithText, .iconOnly]
    }
  }

  public var postVisibility: Models.Visibility {
    if useInstanceContentSettings {
      return serverPreferences?.postVisibility ?? .pub
    } else {
      return appDefaultPostVisibility
    }
  }
  
  public func conformReplyVisibilityConstraints() {
    appDefaultReplyVisibility = getReplyVisibility()
  }
  
  private func getReplyVisibility() -> Models.Visibility {
    getMinVisibility(postVisibility, appDefaultReplyVisibility)
  }
  
  public func getReplyVisibility(of status: Status) -> Models.Visibility {
    getMinVisibility(getReplyVisibility(), status.visibility)
  }
  
  private func getMinVisibility(_ vis1: Models.Visibility, _ vis2: Models.Visibility) -> Models.Visibility {
    let no1 = Self.getIntOfVisibility(vis1)
    let no2 = Self.getIntOfVisibility(vis2)
    
    return no1 < no2 ? vis1 : vis2
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

  public func setNotification(count: Int, token: OauthToken) {
    Self.sharedDefault?.set(count, forKey: "push_notifications_count_\(token.createdAt)")
    objectWillChange.send()
  }

  public func getNotificationsCount(for token: OauthToken) -> Int {
    Self.sharedDefault?.integer(forKey: "push_notifications_count_\(token.createdAt)") ?? 0
  }

  public func getNotificationsTotalCount(for tokens: [OauthToken]) -> Int {
    var count = 0
    for token in tokens {
      count += getNotificationsCount(for: token)
    }
    return count
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
  
  public static func getIntOfVisibility(_ vis: Models.Visibility) -> Int {
    switch vis {
      case .direct:
        return 0
      case .priv:
        return 1
      case .unlisted:
        return 2
      case .pub:
        return 3
    }
  }
}
