import AppAccount
import DesignSystem
import Env
import Models
import Network
import NukeUI
import SwiftUI
import UserNotifications

struct SensitiveContentSettingsView: View {
  
  @EnvironmentObject private var userPreferences: UserPreferences
  @EnvironmentObject private var theme: Theme
  
  @State private var subscriptions: [PushSubscription] = []
  
  var body: some View {
    Form {
      Section {
        Toggle(isOn: $userPreferences.useInstanceContentSettings) {
          Text("settings.sensitive-content.use-instance-settings")
        }
      } footer: {
        VStack{
          Text("settings.sensitive-content.main-toggle.description")
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
      
      Section("Server Settings") {
        LabeledContent("settings.sensitive-content.expand-spoilers", value: userPreferences.serverPreferences?.autoExpandSpoilers == true ? "Yes" : "No")
          .foregroundColor(.secondary)
        LabeledContent("settings.sensitive-content.expand-media", value: "\(ServerPreferences.AutoExpandMedia.showAll.description)")
          .foregroundColor(.secondary)
      }
      
      if !userPreferences.useInstanceContentSettings{
        Section("Application Settings") {
          Toggle(isOn: $userPreferences.appAutoExpandSpoilers) {
            Text("settings.sensitive-content.expand-spoilers")
          }
          Picker("settings.sensitive-content.expand-media", selection: $userPreferences.appAutoExpandMedia) {
            ForEach(ServerPreferences.AutoExpandMedia.allCases, id: \.rawValue) { media in
              Text(media.description).tag(media)
            }
          }
        }
        .listRowBackground(theme.primaryBackgroundColor)
        .transition(.move(edge: .bottom))
      }
    }
    .navigationTitle("settings.sensitive-content.navigation-title")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)


  }

}
