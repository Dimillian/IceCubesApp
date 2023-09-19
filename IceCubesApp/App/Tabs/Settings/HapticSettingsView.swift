import DesignSystem
import Env
import Models
import Status
import SwiftUI

@MainActor
struct HapticSettingsView: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences

  var body: some View {
    @Bindable var userPreferences = userPreferences
    Form {
      Section {
        Toggle("settings.haptic.timeline", isOn: $userPreferences.hapticTimelineEnabled)
        Toggle("settings.haptic.tab-selection", isOn: $userPreferences.hapticTabSelectionEnabled)
        Toggle("settings.haptic.buttons", isOn: $userPreferences.hapticButtonPressEnabled)
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .navigationTitle("settings.haptic.navigation-title")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }
}
