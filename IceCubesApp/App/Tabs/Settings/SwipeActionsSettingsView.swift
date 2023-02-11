import DesignSystem
import Env
import SwiftUI

struct SwipeActionsSettingsView: View {
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var userPreferences: UserPreferences
  
  var body: some View {
    
    Form {
      Section("settings.swipeactions.status") {
        HStack {
          Text("settings.swipeactions.status.leading")
          Image(systemName: "arrow.right")
        }
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
        HStack {
          Text("settings.swipeactions.status.trailing")
          Image(systemName: "arrow.left")
        }
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
    }
    .navigationTitle("settings.swipeactions.navigation-title")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }
  
  private func makeSwipeLabel(left: Bool, text: LocalizedStringKey) -> some View {
    return HStack {
      Image(systemName: left ? "rectangle.lefthalf.filled" : "rectangle.righthalf.filled")
      Text(text)
    }.padding(.leading, 16)
  }
}
