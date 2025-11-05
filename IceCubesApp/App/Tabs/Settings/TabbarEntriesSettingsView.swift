import DesignSystem
import Env
import SwiftUI

@MainActor
struct TabbarEntriesSettingsView: View {
  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var userPreferences

  @State private var tabs = iOSTabs.shared

  var body: some View {
    @Bindable var userPreferences = userPreferences
    Form {
      Section {
        Picker("settings.tabs.first-tab", selection: $tabs.firstTab) {
          ForEach(AppTab.allCases) { tab in
            if tab == tabs.firstTab || !tabs.tabs.contains(tab) {
              tab.label.tag(tab)
            }
          }
        }
        Picker("settings.tabs.second-tab", selection: $tabs.secondTab) {
          ForEach(AppTab.allCases) { tab in
            if tab == tabs.secondTab || !tabs.tabs.contains(tab) {
              tab.label.tag(tab)
            }
          }
        }
        Picker("settings.tabs.third-tab", selection: $tabs.thirdTab) {
          ForEach(AppTab.allCases) { tab in
            if tab == tabs.thirdTab || !tabs.tabs.contains(tab) {
              tab.label.tag(tab)
            }
          }
        }
        Picker("settings.tabs.fourth-tab", selection: $tabs.fourthTab) {
          ForEach(AppTab.allCases) { tab in
            if tab == tabs.fourthTab || !tabs.tabs.contains(tab) {
              tab.label.tag(tab)
            }
          }
        }
        Picker("settings.tabs.fifth-tab", selection: $tabs.fifthTab) {
          ForEach(AppTab.allCases) { tab in
            if tab == tabs.fifthTab || !tabs.tabs.contains(tab) {
              tab.label.tag(tab)
            }
          }
        }
      }
      #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
    .navigationTitle("settings.general.tabbarEntries")
    #if !os(visionOS)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
    #endif
  }
}
