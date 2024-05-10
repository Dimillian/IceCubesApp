import Combine
import Foundation
import Models
import Network
import SwiftUI

@MainActor
@Observable public class UserPreferences {
  class Storage {
    @AppStorage("preferred_browser") public var preferredBrowser: PreferredBrowser = .inAppSafari
    @AppStorage("show_translate_button_inline") public var showTranslateButton: Bool = true
    @AppStorage("show_pending_at_bottom") public var pendingShownAtBottom: Bool = false
    @AppStorage("show_pending_left") public var pendingShownLeft: Bool = false
    @AppStorage("is_open_ai_enabled") public var isOpenAIEnabled: Bool = true

    @AppStorage("recently_used_languages") public var recentlyUsedLanguages: [String] = []
    @AppStorage("social_keyboard_composer") public var isSocialKeyboardEnabled: Bool = false

    @AppStorage("use_instance_content_settings") public var useInstanceContentSettings: Bool = true
    @AppStorage("app_auto_expand_spoilers") public var appAutoExpandSpoilers = false
    @AppStorage("app_auto_expand_media") public var appAutoExpandMedia: ServerPreferences.AutoExpandMedia = .hideSensitive
    @AppStorage("app_default_post_visibility") public var appDefaultPostVisibility: Models.Visibility = .pub
    @AppStorage("app_default_reply_visibility") public var appDefaultReplyVisibility: Models.Visibility = .pub
    @AppStorage("app_default_posts_sensitive") public var appDefaultPostsSensitive = false
    @AppStorage("app_require_alt_text") public var appRequireAltText = false
    @AppStorage("autoplay_video") public var autoPlayVideo = true
    @AppStorage("mute_video") public var muteVideo = true
    @AppStorage("preferred_translation_type") public var preferredTranslationType = TranslationType.useServerIfPossible
    @AppStorage("user_deepl_api_free") public var userDeeplAPIFree = true
    @AppStorage("auto_detect_post_language") public var autoDetectPostLanguage = true

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

    @AppStorage("share-button-behavior") public var shareButtonBehavior: PreferredShareButtonBehavior = .linkOnly

    @AppStorage("fast_refresh") public var fastRefreshEnabled: Bool = false

    @AppStorage("max_reply_indentation") public var maxReplyIndentation: UInt = 7
    @AppStorage("show_reply_indentation") public var showReplyIndentation: Bool = true

    @AppStorage("show_account_popover") public var showAccountPopover: Bool = true

    @AppStorage("sidebar_expanded") public var isSidebarExpanded: Bool = false

    init() {
      prepareTranslationType()
    }

    private func prepareTranslationType() {
      let sharedDefault = UserDefaults.standard
      if let alwaysUseDeepl = (sharedDefault.object(forKey: "always_use_deepl") as? Bool) {
        if alwaysUseDeepl {
          preferredTranslationType = .useDeepl
        }
        sharedDefault.removeObject(forKey: "always_use_deepl")
      }
      #if canImport(_Translation_SwiftUI)
        if #unavailable(iOS 17.4),
           preferredTranslationType == .useApple
        {
          preferredTranslationType = .useServerIfPossible
        }
      #else
        if preferredTranslationType == .useApple {
          preferredTranslationType = .useServerIfPossible
        }
      #endif
    }
  }

  public static let sharedDefault = UserDefaults(suiteName: "group.com.thomasricouard.IceCubesApp")
  public static let shared = UserPreferences()
  private let storage = Storage()

  private var client: Client?

  public var preferredBrowser: PreferredBrowser {
    didSet {
      storage.preferredBrowser = preferredBrowser
    }
  }

  public var showTranslateButton: Bool {
    didSet {
      storage.showTranslateButton = showTranslateButton
    }
  }

  public var pendingShownAtBottom: Bool {
    didSet {
      storage.pendingShownAtBottom = pendingShownAtBottom
    }
  }

  public var pendingShownLeft: Bool {
    didSet {
      storage.pendingShownLeft = pendingShownLeft
    }
  }

  public var pendingLocation: Alignment {
    let fromLeft = Locale.current.language.characterDirection == .leftToRight ? pendingShownLeft : !pendingShownLeft
    if pendingShownAtBottom {
      if fromLeft {
        return .bottomLeading
      } else {
        return .bottomTrailing
      }
    } else {
      if fromLeft {
        return .topLeading
      } else {
        return .topTrailing
      }
    }
  }

  public var isOpenAIEnabled: Bool {
    didSet {
      storage.isOpenAIEnabled = isOpenAIEnabled
    }
  }

  public var recentlyUsedLanguages: [String] {
    didSet {
      storage.recentlyUsedLanguages = recentlyUsedLanguages
    }
  }

  public var isSocialKeyboardEnabled: Bool {
    didSet {
      storage.isSocialKeyboardEnabled = isSocialKeyboardEnabled
    }
  }

  public var useInstanceContentSettings: Bool {
    didSet {
      storage.useInstanceContentSettings = useInstanceContentSettings
    }
  }

  public var appAutoExpandSpoilers: Bool {
    didSet {
      storage.appAutoExpandSpoilers = appAutoExpandSpoilers
    }
  }

  public var appAutoExpandMedia: ServerPreferences.AutoExpandMedia {
    didSet {
      storage.appAutoExpandMedia = appAutoExpandMedia
    }
  }

  public var appDefaultPostVisibility: Models.Visibility {
    didSet {
      storage.appDefaultPostVisibility = appDefaultPostVisibility
    }
  }

  public var appDefaultReplyVisibility: Models.Visibility {
    didSet {
      storage.appDefaultReplyVisibility = appDefaultReplyVisibility
    }
  }

  public var appDefaultPostsSensitive: Bool {
    didSet {
      storage.appDefaultPostsSensitive = appDefaultPostsSensitive
    }
  }

  public var appRequireAltText: Bool {
    didSet {
      storage.appRequireAltText = appRequireAltText
    }
  }

  public var autoPlayVideo: Bool {
    didSet {
      storage.autoPlayVideo = autoPlayVideo
    }
  }

  public var muteVideo: Bool {
    didSet {
      storage.muteVideo = muteVideo
    }
  }

  public var preferredTranslationType: TranslationType {
    didSet {
      storage.preferredTranslationType = preferredTranslationType
    }
  }

  public var userDeeplAPIFree: Bool {
    didSet {
      storage.userDeeplAPIFree = userDeeplAPIFree
    }
  }

  public var autoDetectPostLanguage: Bool {
    didSet {
      storage.autoDetectPostLanguage = autoDetectPostLanguage
    }
  }

  public var inAppBrowserReaderView: Bool {
    didSet {
      storage.inAppBrowserReaderView = inAppBrowserReaderView
    }
  }

  public var hapticTabSelectionEnabled: Bool {
    didSet {
      storage.hapticTabSelectionEnabled = hapticTabSelectionEnabled
    }
  }

  public var hapticTimelineEnabled: Bool {
    didSet {
      storage.hapticTimelineEnabled = hapticTimelineEnabled
    }
  }

  public var hapticButtonPressEnabled: Bool {
    didSet {
      storage.hapticButtonPressEnabled = hapticButtonPressEnabled
    }
  }

  public var soundEffectEnabled: Bool {
    didSet {
      storage.soundEffectEnabled = soundEffectEnabled
    }
  }

  public var showiPhoneTabLabel: Bool {
    didSet {
      storage.showiPhoneTabLabel = showiPhoneTabLabel
    }
  }

  public var showAltTextForMedia: Bool {
    didSet {
      storage.showAltTextForMedia = showAltTextForMedia
    }
  }

  public var showiPadSecondaryColumn: Bool {
    didSet {
      storage.showiPadSecondaryColumn = showiPadSecondaryColumn
    }
  }

  public var swipeActionsStatusTrailingRight: StatusAction {
    didSet {
      storage.swipeActionsStatusTrailingRight = swipeActionsStatusTrailingRight
    }
  }

  public var swipeActionsStatusTrailingLeft: StatusAction {
    didSet {
      storage.swipeActionsStatusTrailingLeft = swipeActionsStatusTrailingLeft
    }
  }

  public var swipeActionsStatusLeadingLeft: StatusAction {
    didSet {
      storage.swipeActionsStatusLeadingLeft = swipeActionsStatusLeadingLeft
    }
  }

  public var swipeActionsStatusLeadingRight: StatusAction {
    didSet {
      storage.swipeActionsStatusLeadingRight = swipeActionsStatusLeadingRight
    }
  }

  public var swipeActionsUseThemeColor: Bool {
    didSet {
      storage.swipeActionsUseThemeColor = swipeActionsUseThemeColor
    }
  }

  public var swipeActionsIconStyle: SwipeActionsIconStyle {
    didSet {
      storage.swipeActionsIconStyle = swipeActionsIconStyle
    }
  }

  public var requestedReview: Bool {
    didSet {
      storage.requestedReview = requestedReview
    }
  }

  public var collapseLongPosts: Bool {
    didSet {
      storage.collapseLongPosts = collapseLongPosts
    }
  }

  public var shareButtonBehavior: PreferredShareButtonBehavior {
    didSet {
      storage.shareButtonBehavior = shareButtonBehavior
    }
  }

  public var fastRefreshEnabled: Bool {
    didSet {
      storage.fastRefreshEnabled = fastRefreshEnabled
    }
  }

  public var maxReplyIndentation: UInt {
    didSet {
      storage.maxReplyIndentation = maxReplyIndentation
    }
  }

  public var showReplyIndentation: Bool {
    didSet {
      storage.showReplyIndentation = showReplyIndentation
    }
  }

  public var showAccountPopover: Bool {
    didSet {
      storage.showAccountPopover = showAccountPopover
    }
  }

  public var isSidebarExpanded: Bool {
    didSet {
      storage.isSidebarExpanded = isSidebarExpanded
    }
  }

  public func getRealMaxIndent() -> UInt {
    showReplyIndentation ? maxReplyIndentation : 0
  }

  public enum SwipeActionsIconStyle: String, CaseIterable {
    case iconWithText, iconOnly

    public var description: LocalizedStringKey {
      switch self {
      case .iconWithText:
        "enum.swipeactions.icon-with-text"
      case .iconOnly:
        "enum.swipeactions.icon-only"
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
      serverPreferences?.postVisibility ?? .pub
    } else {
      appDefaultPostVisibility
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
      serverPreferences?.postIsSensitive ?? false
    } else {
      appDefaultPostsSensitive
    }
  }

  public var autoExpandSpoilers: Bool {
    if useInstanceContentSettings {
      serverPreferences?.autoExpandSpoilers ?? true
    } else {
      appAutoExpandSpoilers
    }
  }

  public var autoExpandMedia: ServerPreferences.AutoExpandMedia {
    if useInstanceContentSettings {
      serverPreferences?.autoExpandMedia ?? .hideSensitive
    } else {
      appAutoExpandMedia
    }
  }

  public var notificationsCount: [OauthToken: Int] = [:] {
    didSet {
      for (key, value) in notificationsCount {
        Self.sharedDefault?.set(value, forKey: "push_notifications_count_\(key.createdAt)")
      }
    }
  }

  public var totalNotificationsCount: Int {
    notificationsCount.compactMap { $0.value }.reduce(0, +)
  }

  public func reloadNotificationsCount(tokens: [OauthToken]) {
    notificationsCount = [:]
    for token in tokens {
      notificationsCount[token] = Self.sharedDefault?.integer(forKey: "push_notifications_count_\(token.createdAt)") ?? 0
    }
  }

  public var serverPreferences: ServerPreferences?

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
      0
    case .priv:
      1
    case .unlisted:
      2
    case .pub:
      3
    }
  }

  private init() {
    preferredBrowser = storage.preferredBrowser
    showTranslateButton = storage.showTranslateButton
    isOpenAIEnabled = storage.isOpenAIEnabled
    recentlyUsedLanguages = storage.recentlyUsedLanguages
    isSocialKeyboardEnabled = storage.isSocialKeyboardEnabled
    useInstanceContentSettings = storage.useInstanceContentSettings
    appAutoExpandSpoilers = storage.appAutoExpandSpoilers
    appAutoExpandMedia = storage.appAutoExpandMedia
    appDefaultPostVisibility = storage.appDefaultPostVisibility
    appDefaultReplyVisibility = storage.appDefaultReplyVisibility
    appDefaultPostsSensitive = storage.appDefaultPostsSensitive
    appRequireAltText = storage.appRequireAltText
    autoPlayVideo = storage.autoPlayVideo
    preferredTranslationType = storage.preferredTranslationType
    userDeeplAPIFree = storage.userDeeplAPIFree
    autoDetectPostLanguage = storage.autoDetectPostLanguage
    inAppBrowserReaderView = storage.inAppBrowserReaderView
    hapticTabSelectionEnabled = storage.hapticTabSelectionEnabled
    hapticTimelineEnabled = storage.hapticTimelineEnabled
    hapticButtonPressEnabled = storage.hapticButtonPressEnabled
    soundEffectEnabled = storage.soundEffectEnabled
    showiPhoneTabLabel = storage.showiPhoneTabLabel
    showAltTextForMedia = storage.showAltTextForMedia
    showiPadSecondaryColumn = storage.showiPadSecondaryColumn
    swipeActionsStatusTrailingRight = storage.swipeActionsStatusTrailingRight
    swipeActionsStatusTrailingLeft = storage.swipeActionsStatusTrailingLeft
    swipeActionsStatusLeadingLeft = storage.swipeActionsStatusLeadingLeft
    swipeActionsStatusLeadingRight = storage.swipeActionsStatusLeadingRight
    swipeActionsUseThemeColor = storage.swipeActionsUseThemeColor
    swipeActionsIconStyle = storage.swipeActionsIconStyle
    requestedReview = storage.requestedReview
    collapseLongPosts = storage.collapseLongPosts
    shareButtonBehavior = storage.shareButtonBehavior
    pendingShownAtBottom = storage.pendingShownAtBottom
    pendingShownLeft = storage.pendingShownLeft
    fastRefreshEnabled = storage.fastRefreshEnabled
    maxReplyIndentation = storage.maxReplyIndentation
    showReplyIndentation = storage.showReplyIndentation
    showAccountPopover = storage.showAccountPopover
    muteVideo = storage.muteVideo
    isSidebarExpanded = storage.isSidebarExpanded
  }
}

extension UInt: RawRepresentable {
  public var rawValue: Int {
    Int(self)
  }

  public init?(rawValue: Int) {
    if rawValue >= 0 {
      self.init(rawValue)
    } else {
      return nil
    }
  }
}
