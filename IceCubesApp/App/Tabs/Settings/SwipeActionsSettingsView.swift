import DesignSystem
import Env
import SwiftUI

struct SwipeActionsSettingsView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var userPreferences: UserPreferences

  var body: some View {
    
    Form {
      Section("settings.swipeactions.status") {
        Picker("settings.swipeactions.status.left.1",
               selection: $userPreferences.swipeActionsStatusLeft1) {
          ForEach(StatusAction.allCases, id: \.rawValue) { action in
            Text(action.displayName).tag(action)
          }
        }
        Picker("settings.swipeactions.status.left.2",
               selection: $userPreferences.swipeActionsStatusLeft2) {
          ForEach(StatusAction.allCases, id: \.rawValue) { action in
            Text(action.displayName).tag(action)
          }
        }
        Picker("settings.swipeactions.status.right.1",
               selection: $userPreferences.swipeActionsStatusRight1) {
          ForEach(StatusAction.allCases, id: \.rawValue) { action in
            Text(action.displayName).tag(action)
          }
        }
        Picker("settings.swipeactions.status.right.2",
               selection: $userPreferences.swipeActionsStatusRight2) {
          ForEach(StatusAction.allCases, id: \.rawValue) { action in
            Text(action.displayName).tag(action)
          }
        }
      }
    }
    .navigationTitle("settings.swipeactions.navigation-title")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }
}
