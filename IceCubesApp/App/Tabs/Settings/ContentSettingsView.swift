import AppAccount
import DesignSystem
import Env
import Models
import NetworkClient
import NukeUI
import SwiftUI
import Timeline
import UserNotifications

@MainActor
struct ContentSettingsView: View {
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(Theme.self) private var theme

  @State private var contentFilter = TimelineContentFilter.shared

  var body: some View {
    @Bindable var userPreferences = userPreferences
    Form {
      Section("settings.content.media") {
        Toggle(isOn: $userPreferences.autoPlayVideo) {
          Text("settings.other.autoplay-video")
        }
        Toggle(isOn: $userPreferences.muteVideo) {
          Text("settings.other.mute-video")
        }
        Toggle(isOn: $userPreferences.showAltTextForMedia) {
          Text("settings.content.media.show.alt")
        }
        Toggle(isOn: $userPreferences.animateEmojis) {
            Text("settings.other.animate-emojis")
        }
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif

      Section("settings.content.sharing") {
        Picker(
          "settings.content.sharing.share-button-behavior",
          selection: $userPreferences.shareButtonBehavior
        ) {
          ForEach(PreferredShareButtonBehavior.allCases, id: \.rawValue) { option in
            Text(option.title)
              .tag(option)
          }
        }
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif

      Section("settings.content.instance-settings") {
        Toggle(isOn: $userPreferences.useInstanceContentSettings) {
          Text("settings.content.use-instance-settings")
        }
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif
      .onChange(of: userPreferences.useInstanceContentSettings) { _, newVal in
        if newVal {
          userPreferences.appAutoExpandSpoilers = userPreferences.autoExpandSpoilers
          userPreferences.appAutoExpandMedia = userPreferences.autoExpandMedia
          userPreferences.appDefaultPostsSensitive = userPreferences.postIsSensitive
          userPreferences.appDefaultPostVisibility = userPreferences.postVisibility
          userPreferences.appRequireAltText = userPreferences.appRequireAltText
        }
      }

      Section {
        Toggle(isOn: $userPreferences.appAutoExpandSpoilers) {
          Text("settings.content.expand-spoilers")
        }
        .disabled(userPreferences.useInstanceContentSettings)

        Picker("settings.content.expand-media", selection: $userPreferences.appAutoExpandMedia) {
          ForEach(ServerPreferences.AutoExpandMedia.allCases, id: \.rawValue) { media in
            Text(media.description).tag(media)
          }
        }
        .disabled(userPreferences.useInstanceContentSettings)

        Toggle(isOn: $userPreferences.collapseLongPosts) {
          Text("settings.content.collapse-long-posts")
        }
      } header: {
        Text("settings.content.reading")
      } footer: {
        Text("settings.content.collapse-long-posts-hint")
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif

      Section("settings.content.posting") {
        Picker(
          "settings.content.default-visibility",
          selection: $userPreferences.appDefaultPostVisibility
        ) {
          ForEach(Visibility.allCases, id: \.rawValue) { vis in
            Text(vis.title).tag(vis)
          }
        }
        .disabled(userPreferences.useInstanceContentSettings)

        Picker(
          "settings.content.default-reply-visibility",
          selection: $userPreferences.appDefaultReplyVisibility
        ) {
          ForEach(Visibility.allCases, id: \.rawValue) { vis in
            if UserPreferences.getIntOfVisibility(vis)
              <= UserPreferences.getIntOfVisibility(userPreferences.postVisibility)
            {
              Text(vis.title).tag(vis)
            }
          }
        }
        .onChange(of: userPreferences.postVisibility) {
          userPreferences.conformReplyVisibilityConstraints()
        }

        Toggle(isOn: $userPreferences.appDefaultPostsSensitive) {
          Text("settings.content.default-sensitive")
        }
        .disabled(userPreferences.useInstanceContentSettings)

        Toggle(isOn: $userPreferences.appRequireAltText) {
          Text("settings.content.require-alt-text")
        }
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif

      Section("timeline.content-filter.title") {
        Toggle(isOn: $contentFilter.showBoosts) {
          Label("timeline.filter.show-boosts", systemImage: "arrow.2.squarepath")
        }
        Toggle(isOn: $contentFilter.showReplies) {
          Label("timeline.filter.show-replies", systemImage: "bubble.left.and.bubble.right")
        }
        Toggle(isOn: $contentFilter.showThreads) {
          Label("timeline.filter.show-threads", systemImage: "bubble.left.and.text.bubble.right")
        }
        Toggle(isOn: $contentFilter.showQuotePosts) {
          Label("timeline.filter.show-quote", systemImage: "quote.bubble")
        }
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif

      Section("Notifications") {
        Toggle(isOn: $userPreferences.notificationsTruncateStatusContent) {
          Text("Truncate status content")
        }
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
    .navigationTitle("settings.content.navigation-title")
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
    #endif
  }
}
