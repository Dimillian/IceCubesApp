import DesignSystem
import Env
import SwiftUI

struct SwipeActionsSettingsView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var userPreferences: UserPreferences
  
  var body: some View {
    
    Form {
      Section("settings.swipeactions.status") {
        Label("settings.swipeactions.status.leading", systemImage: "arrow.left.circle")
        Picker(selection: $userPreferences.swipeActionsStatusLeadingLeft, label: makeSwipeLabel(left: true, text: "settings.swipeactions.status.leading.left")) {
          ForEach(StatusAction.allCases) { action in
            Text(action.displayName).tag(action)
          }
        }
        Picker(selection: $userPreferences.swipeActionsStatusLeadingRight, label: makeSwipeLabel(left: false, text: "settings.swipeactions.status.leading.right")) {
          ForEach(StatusAction.allCases) { action in
            Text(action.displayName).tag(action)
          }
        }
        Label("settings.swipeactions.status.trailing", systemImage: "arrow.right.circle")
        Picker(selection: $userPreferences.swipeActionsStatusTrailingLeft, label: makeSwipeLabel(left: true, text: "settings.swipeactions.status.trailing.left"))  {
          ForEach(StatusAction.allCases) { action in
            Text(action.displayName).tag(action)
          }
        }
        Picker(selection: $userPreferences.swipeActionsStatusTrailingRight, label: makeSwipeLabel(left: false, text: "settings.swipeactions.status.trailing.right")) {
          ForEach(StatusAction.allCases) { action in
            Text(action.displayName).tag(action)
          }
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .navigationTitle("settings.swipeactions.navigation-title")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }
  
  private func makeSwipeLabel(left: Bool, text: LocalizedStringKey) -> some View {
    return Label(text, systemImage: left ? "rectangle.lefthalf.filled" : "rectangle.righthalf.filled")
           .padding(.leading, 16)
  }
}
