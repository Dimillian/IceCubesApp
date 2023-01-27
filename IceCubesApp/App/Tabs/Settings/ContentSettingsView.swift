import AppAccount
import DesignSystem
import Env
import Models
import Network
import NukeUI
import SwiftUI
import UserNotifications

struct ContentSettingsView: View {
  @EnvironmentObject private var userPreferences: UserPreferences
  @EnvironmentObject private var theme: Theme

  var body: some View {
    Form {
      Section {
        Toggle(isOn: $userPreferences.useInstanceContentSettings) {
          Text("settings.content.use-instance-settings")
        }
      } footer: {
        Text("settings.content.main-toggle.description")
      }
      .listRowBackground(theme.primaryBackgroundColor)
      .onChange(of: userPreferences.useInstanceContentSettings) { newVal in
        if newVal {
          userPreferences.appAutoExpandSpoilers = userPreferences.autoExpandSpoilers
          userPreferences.appAutoExpandMedia = userPreferences.autoExpandMedia
          userPreferences.appDefaultPostsSensitive = userPreferences.postIsSensitive
          userPreferences.appDefaultPostVisibility = userPreferences.postVisibility
        }
      }

      Section("settings.content.reading") {
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
      }.listRowBackground(theme.primaryBackgroundColor)

      Section("settings.content.posting") {
        Picker("settings.content.default-visibility", selection: $userPreferences.appDefaultPostVisibility) {
          ForEach(Visibility.allCases, id: \.rawValue) { vis in
            Text(vis.title).tag(vis)
          }
        }
        .disabled(userPreferences.useInstanceContentSettings)

        Toggle(isOn: $userPreferences.appDefaultPostsSensitive) {
          Text("settings.content.default-sensitive")
        }
        .disabled(userPreferences.useInstanceContentSettings)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .navigationTitle("settings.content.navigation-title")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }
}
