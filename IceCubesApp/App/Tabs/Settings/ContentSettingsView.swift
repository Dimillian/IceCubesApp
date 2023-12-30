import AppAccount
import DesignSystem
import Env
import Models
import Network
import NukeUI
import SwiftUI
import UserNotifications

@MainActor
struct ContentSettingsView: View {
  @Environment(UserPreferences.self) private var userPreferences
  @Environment(Theme.self) private var theme

  var body: some View {
    @Bindable var userPreferences = userPreferences
    Form {
      Section("settings.content.boosts") {
        Toggle(isOn: $userPreferences.suppressDupeReblogs) {
          Text("settings.content.hide-repeated-boosts")
        }
      }
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
      #endif

      Section("settings.content.media") {
        Toggle(isOn: $userPreferences.autoPlayVideo) {
          Text("settings.other.autoplay-video")
        }
        Toggle(isOn: $userPreferences.showAltTextForMedia) {
          Text("settings.content.media.show.alt")
        }
      }
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
      #endif

      Section("settings.content.sharing") {
        Picker("settings.content.sharing.share-button-behavior", selection: $userPreferences.shareButtonBehavior) {
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
        Picker("settings.content.default-visibility", selection: $userPreferences.appDefaultPostVisibility) {
          ForEach(Visibility.allCases, id: \.rawValue) { vis in
            Text(vis.title).tag(vis)
          }
        }
        .disabled(userPreferences.useInstanceContentSettings)

        Picker("settings.content.default-reply-visibility", selection: $userPreferences.appDefaultReplyVisibility) {
          ForEach(Visibility.allCases, id: \.rawValue) { vis in
            if UserPreferences.getIntOfVisibility(vis) <=
              UserPreferences.getIntOfVisibility(userPreferences.postVisibility)
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
