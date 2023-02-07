import DesignSystem
import Env
import Models
import Status
import SwiftUI

struct HapticSettingsView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var userPreferences: UserPreferences

  var body: some View {
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
