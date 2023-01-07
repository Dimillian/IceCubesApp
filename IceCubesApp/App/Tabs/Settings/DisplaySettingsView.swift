import SwiftUI
import Models
import DesignSystem
import Status

struct DisplaySettingsView: View {
  @EnvironmentObject private var theme: Theme
  
  @State private var isThemeSelectorPresented = false
  
  var body: some View {
    Form {
      Section("Theme") {
        themeSelectorButton
        ColorPicker("Tint color", selection: $theme.tintColor)
        ColorPicker("Background color", selection: $theme.primaryBackgroundColor)
        ColorPicker("Secondary Background color", selection: $theme.secondaryBackgroundColor)
      }
      .listRowBackground(theme.primaryBackgroundColor)
      
      Section("Display") {
        Picker("Avatar position", selection: $theme.avatarPosition) {
          ForEach(Theme.AvatarPosition.allCases, id: \.rawValue) { position in
            Text(position.description).tag(position)
          }
        }
        Picker("Avatar shape", selection: $theme.avatarShape) {
          ForEach(Theme.AvatarShape.allCases, id: \.rawValue) { shape in
            Text(shape.description).tag(shape)
          }
        }
        Picker("Status actions buttons", selection: $theme.statusActionsDisplay) {
          ForEach(Theme.StatusActionsDisplay.allCases, id: \.rawValue) { buttonStyle in
            Text(buttonStyle.description).tag(buttonStyle)
          }
        }
        
        Picker("Status media style", selection: $theme.statusDisplayStyle) {
          ForEach(Theme.StatusDisplayStyle.allCases, id: \.rawValue) { buttonStyle in
            Text(buttonStyle.description).tag(buttonStyle)
          }
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
      
      Section {
        Button {
          theme.selectedSet = .iceCubeDark
          theme.avatarShape = .rounded
          theme.avatarPosition = .top
          theme.statusActionsDisplay = .full
        } label: {
          Text("Restore default")
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
    }
    .navigationTitle("Display Settings")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
  }
  
  private var themeSelectorButton: some View {
    NavigationLink(destination: ThemePreviewView()) {
      HStack {
        Text("Theme")
        Spacer()
        Text(theme.selectedSet.rawValue)
      }
    }
  }
}
