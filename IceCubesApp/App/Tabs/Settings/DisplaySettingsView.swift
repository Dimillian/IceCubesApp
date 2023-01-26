import DesignSystem
import Env
import Models
import Status
import SwiftUI

struct DisplaySettingsView: View {
  @Environment(\.colorScheme) private var colorScheme
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var userPreferences: UserPreferences

  @State private var isThemeSelectorPresented = false

  var body: some View {
    Form {
      Section {
        Toggle("settings.display.theme.systemColor", isOn: $theme.followSystemColorScheme)
        themeSelectorButton
        Group {
          ColorPicker("settings.display.theme.tint", selection: $theme.tintColor)
          ColorPicker("settings.display.theme.background", selection: $theme.primaryBackgroundColor)
          ColorPicker("settings.display.theme.secondary-background", selection: $theme.secondaryBackgroundColor)
        }
        .disabled(theme.followSystemColorScheme)
        .opacity(theme.followSystemColorScheme ? 0.5 : 1.0)
      } header: {
        Text("settings.display.section.theme")
      } footer: {
        if theme.followSystemColorScheme {
          Text("settings.display.section.theme.footer")
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)

      Section("settings.display.section.display") {
        Picker("settings.display.avatar.position", selection: $theme.avatarPosition) {
          ForEach(Theme.AvatarPosition.allCases, id: \.rawValue) { position in
            Text(position.description).tag(position)
          }
        }
        Picker("settings.display.avatar.shape", selection: $theme.avatarShape) {
          ForEach(Theme.AvatarShape.allCases, id: \.rawValue) { shape in
            Text(shape.description).tag(shape)
          }
        }
        Picker("settings.display.status.action-buttons", selection: $theme.statusActionsDisplay) {
          ForEach(Theme.StatusActionsDisplay.allCases, id: \.rawValue) { buttonStyle in
            Text(buttonStyle.description).tag(buttonStyle)
          }
        }

        Picker("settings.display.status.media-style", selection: $theme.statusDisplayStyle) {
          ForEach(Theme.StatusDisplayStyle.allCases, id: \.rawValue) { buttonStyle in
            Text(buttonStyle.description).tag(buttonStyle)
          }
        }
        if ProcessInfo.processInfo.isiOSAppOnMac {
          VStack {
            Slider(value: $userPreferences.fontSizeScale, in: 0.5 ... 1.5, step: 0.1)
            Text("Font scaling: \(String(format: "%.1f", userPreferences.fontSizeScale))")
              .font(.scaledBody)
          }
        }
        Toggle("settings.display.translate-button", isOn: $userPreferences.showTranslateButton)
      }
      .listRowBackground(theme.primaryBackgroundColor)

      Section {
        Button {
          theme.followSystemColorScheme = true
          theme.selectedSet = colorScheme == .dark ? .iceCubeDark : .iceCubeLight
          theme.avatarShape = .rounded
          theme.avatarPosition = .top
          theme.statusActionsDisplay = .full
        } label: {
          Text("settings.display.restore")
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .navigationTitle("settings.display.navigation-title")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }

  private var themeSelectorButton: some View {
    NavigationLink(destination: ThemePreviewView()) {
      HStack {
        Text("settings.display.section.theme")
        Spacer()
        Text(theme.selectedSet.rawValue)
      }
    }
  }
}
