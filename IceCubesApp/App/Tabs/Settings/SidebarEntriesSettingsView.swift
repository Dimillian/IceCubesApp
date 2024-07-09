import DesignSystem
import Env
import SwiftUI

@MainActor
struct SidebarEntriesSettingsView: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences

  @State private var sidebarTabs = SidebarTabs.shared

  var body: some View {
    @Bindable var userPreferences = userPreferences
    Form {
      Section {
        ForEach($sidebarTabs.tabs, id: \.tab) { $tab in
          if tab.tab != .profile && tab.tab != .settings {
            Toggle(isOn: $tab.enabled) {
              tab.tab.label
            }
          }
        }
        .onMove(perform: move)
      }
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
    .environment(\.editMode, .constant(.active))
    .navigationTitle("settings.general.sidebarEntries")
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
    #endif
  }

  func move(from source: IndexSet, to destination: Int) {
    sidebarTabs.tabs.move(fromOffsets: source, toOffset: destination)
  }
}
