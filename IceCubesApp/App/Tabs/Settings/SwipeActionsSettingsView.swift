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
                             label: "settings.swipeactions.status.leading.left")
        
        if userPreferences.swipeActionsStatusLeadingLeft != .none {
          makePostActionPicker(selection: $userPreferences.swipeActionsStatusLeadingRight,
                               label: "settings.swipeactions.status.leading.right")
        }
      } header: {
        Label("settings.swipeactions.status.leading", systemImage: "arrow.right")
      }
      
      Section {
        makePostActionPicker(selection: $userPreferences.swipeActionsStatusTrailingLeft,
                             label: "settings.swipeactions.status.trailing.left")
        
        if userPreferences.swipeActionsStatusTrailingLeft != .none {
          makePostActionPicker(selection: $userPreferences.swipeActionsStatusTrailingRight,
                               label: "settings.swipeactions.status.trailing.right")
        }
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
          Text("Use Theme Colors")
        }
      } header: {
        Text("Action Display Settings")
      } footer: {
        Text("settings.swipeactions.status.use-theme-colors")
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .navigationTitle("settings.swipeactions.navigation-title")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }

  private func makeSwipeLabel(left: Bool, text: LocalizedStringKey) -> some View {
    return Label(text, systemImage: left ? "rectangle.lefthalf.filled" : "rectangle.righthalf.filled")
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
