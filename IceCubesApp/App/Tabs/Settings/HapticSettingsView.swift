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
      if true {
        Section {
          Toggle("settings.haptic.timeline", isOn: $userPreferences.hapticTimelineEnabled)
          Toggle("settings.haptic.tab-selection", isOn: $userPreferences.hapticTabSelectionEnabled)
          Toggle("settings.haptic.buttons", isOn: $userPreferences.hapticButtonPressEnabled)
        } header: {
          Text("Haptic Feedback")
        }
        .listRowBackground(theme.primaryBackgroundColor)
      }
      Section {
        Toggle("settings.other.sound-effect", isOn: $userPreferences.soundEffectEnabled)
      } header: {
        Text("Sound Effects")
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .navigationTitle("Sounds and Haptics")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }
}
