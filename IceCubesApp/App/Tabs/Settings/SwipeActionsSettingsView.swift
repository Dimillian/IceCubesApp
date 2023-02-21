import DesignSystem
import Env
import SwiftUI

struct SwipeActionsSettingsView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var userPreferences: UserPreferences

  var body: some View {
    Form {
      Section {
                
        Label("settings.swipeactions.status.leading", systemImage: "arrow.right")
          .foregroundColor(.secondary)
        
        createStatusActionPicker(selection: $userPreferences.swipeActionsStatusLeadingLeft,
                             label: "settings.swipeactions.primary")
          .onChange(of: userPreferences.swipeActionsStatusLeadingLeft) { action in
            if action == .none {
              userPreferences.swipeActionsStatusLeadingRight = .none;
            }
          }
        
        createStatusActionPicker(selection: $userPreferences.swipeActionsStatusLeadingRight,
                               label: "settings.swipeactions.secondary")
        .disabled(userPreferences.swipeActionsStatusLeadingLeft == .none)
        
        Label("settings.swipeactions.status.trailing", systemImage: "arrow.left")
          .foregroundColor(.secondary)
        
        createStatusActionPicker(selection: $userPreferences.swipeActionsStatusTrailingRight,
                             label: "settings.swipeactions.primary")
          .onChange(of: userPreferences.swipeActionsStatusTrailingRight) { action in
            if action == .none {
              userPreferences.swipeActionsStatusTrailingLeft = .none;
            }
          }

        createStatusActionPicker(selection: $userPreferences.swipeActionsStatusTrailingLeft,
                               label: "settings.swipeactions.secondary")
          .disabled(userPreferences.swipeActionsStatusTrailingRight == .none)
        
      } header: {
        Text("settings.swipeactions.status")
      } footer: {
        Text("settings.swipeactions.status.explanation")
      }
      .listRowBackground(theme.primaryBackgroundColor)

      Section {
        Picker(selection: $userPreferences.swipeActionsIconStyle, label: Text("settings.swipeactions.icon-style")) {
          ForEach(UserPreferences.SwipeActionsIconStyle.allCases, id: \.rawValue) { style in
            Text(style.description).tag(style)
          }
        }
        Toggle(isOn: $userPreferences.swipeActionsUseThemeColor) {
          // TODO: Localization
          Text("Use Theme Colors")
        }
      } header: {
        Text("settings.swipeactions.appearance")
      } footer: {
        // TODO: Localization
        Text("settings.swipeactions.use-theme-colors")
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .navigationTitle("settings.swipeactions.navigation-title")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }

  private func createStatusActionPicker(selection: Binding<StatusAction>, label: LocalizedStringKey) -> some View {
    return Picker(selection: selection, label: Text(label)) {
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
