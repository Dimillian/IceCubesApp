import DesignSystem
import Env
import SwiftUI

@MainActor
struct SwipeActionsSettingsView: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences

  var body: some View {
    @Bindable var userPreferences = userPreferences
    Form {
      Section {
        Label("settings.swipeactions.status.leading", systemImage: "arrow.right")
          .foregroundColor(.secondary)

        createStatusActionPicker(
          selection: $userPreferences.swipeActionsStatusLeadingLeft,
          label: "settings.swipeactions.primary"
        )
        .onChange(of: userPreferences.swipeActionsStatusLeadingLeft) { _, action in
          if action == .none {
            userPreferences.swipeActionsStatusLeadingRight = .none
          }
        }

        createStatusActionPicker(
          selection: $userPreferences.swipeActionsStatusLeadingRight,
          label: "settings.swipeactions.secondary"
        )
        .disabled(userPreferences.swipeActionsStatusLeadingLeft == .none)

        Label("settings.swipeactions.status.trailing", systemImage: "arrow.left")
          .foregroundColor(.secondary)

        createStatusActionPicker(
          selection: $userPreferences.swipeActionsStatusTrailingRight,
          label: "settings.swipeactions.primary"
        )
        .onChange(of: userPreferences.swipeActionsStatusTrailingRight) { _, action in
          if action == .none {
            userPreferences.swipeActionsStatusTrailingLeft = .none
          }
        }

        createStatusActionPicker(
          selection: $userPreferences.swipeActionsStatusTrailingLeft,
          label: "settings.swipeactions.secondary"
        )
        .disabled(userPreferences.swipeActionsStatusTrailingRight == .none)

      } header: {
        Text("settings.swipeactions.status")
      } footer: {
        Text("settings.swipeactions.status.explanation")
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif

      Section {
        Picker(
          selection: $userPreferences.swipeActionsIconStyle,
          label: Text("settings.swipeactions.icon-style")
        ) {
          ForEach(UserPreferences.SwipeActionsIconStyle.allCases, id: \.rawValue) { style in
            Text(style.description).tag(style)
          }
        }
        Toggle(isOn: $userPreferences.swipeActionsUseThemeColor) {
          Text("settings.swipeactions.use-theme-colors")
        }
      } header: {
        Text("settings.swipeactions.appearance")
      } footer: {
        Text("settings.swipeactions.use-theme-colors-explanation")
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
    .navigationTitle("settings.swipeactions.navigation-title")
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
    #endif
  }

  private func createStatusActionPicker(selection: Binding<StatusAction>, label: LocalizedStringKey)
    -> some View
  {
    Picker(selection: selection, label: Text(label)) {
      Section {
        Text(StatusAction.none.displayName()).tag(StatusAction.none)
      }
      Section {
        ForEach(StatusAction.allCases) { action in
          if action != .none {
            Text(action.displayName()).tag(action)
          }
        }
      }
    }
  }
}
