import DesignSystem
import Env
import SwiftUI

struct SwipeActionsSettingsView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var userPreferences: UserPreferences

  var body: some View {
    Form {
      Section {
        makePostActionPicker(selection: $userPreferences.swipeActionsStatusLeadingLeft,
                             label: "settings.swipeactions.status.primary")
          .onChange(of: userPreferences.swipeActionsStatusLeadingLeft) { action in
            if action == .none {
              userPreferences.swipeActionsStatusLeadingRight = .none;
            }
          }
        
        makePostActionPicker(selection: $userPreferences.swipeActionsStatusLeadingRight,
                               label: "settings.swipeactions.status.secondary")
        .disabled(userPreferences.swipeActionsStatusLeadingLeft == .none)
        
      } header: {
        Label("settings.swipeactions.status.leading", systemImage: "arrow.right")
      }
      
      Section {
        makePostActionPicker(selection: $userPreferences.swipeActionsStatusTrailingRight,
                             label: "settings.swipeactions.status.primary")
          .onChange(of: userPreferences.swipeActionsStatusTrailingRight) { action in
            if action == .none {
              userPreferences.swipeActionsStatusTrailingLeft = .none;
            }
          }

        makePostActionPicker(selection: $userPreferences.swipeActionsStatusTrailingLeft,
                               label: "settings.swipeactions.status.secondary")
          .disabled(userPreferences.swipeActionsStatusTrailingRight == .none)
        
      } header: {
        Label("settings.swipeactions.status.trailing", systemImage: "arrow.left")

      }

      Section {
        Picker(selection: $userPreferences.swipeActionsIconStyle, label: Text("settings.swipeactions.status.icon-style")) {
          ForEach(UserPreferences.SwipeActionsIconStyle.allCases, id: \.rawValue) { style in
            Text(style.description).tag(style)
          }
        }
        Toggle(isOn: $userPreferences.swipeActionsUseThemeColor) {
          // TODO: Localization
          Text("Use Theme Colors")
        }
      } header: {
        // TODO: Localization
        Text("Appearance")
      } footer: {
        // TODO: Localization
        Text("settings.swipeactions.status.use-theme-colors")
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .navigationTitle("settings.swipeactions.navigation-title")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }
  
  private func makePostActionPicker(selection: Binding<StatusAction>, label: LocalizedStringKey) -> some View {
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
