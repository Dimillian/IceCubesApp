import DesignSystem
import Env
import SwiftUI

struct TranslationSettingsView: View {
  @EnvironmentObject private var preferences: UserPreferences
  @Environment(Theme.self) private var theme

  @State private var apiKey: String = ""

  var body: some View {
    Form {
      Toggle(isOn: preferences.$alwaysUseDeepl) {
        Text("settings.translation.always-deepl")
      }
      .listRowBackground(theme.primaryBackgroundColor)

      if preferences.alwaysUseDeepl {
        Section("settings.translation.user-api-key") {
          Picker("settings.translation.api-key-type", selection: $preferences.userDeeplAPIFree) {
            Text("DeepL API Free").tag(true)
            Text("DeepL API Pro").tag(false)
          }

          SecureField("settings.translation.user-api-key", text: $apiKey)
            .textContentType(.password)
        }
        .onAppear {
          readValue()
        }
        .listRowBackground(theme.primaryBackgroundColor)

        if apiKey.isEmpty {
          Section {
            Link(destination: URL(string: "https://www.deepl.com/pro-api")!) {
              Text("settings.translation.needed-message")
                .foregroundColor(.red)
            }
          }
          .listRowBackground(theme.primaryBackgroundColor)
        }
      }

      Section {
        Toggle(isOn: preferences.$autoDetectPostLanguage) {
          Text("settings.translation.auto-detect-post-language")
        }
      } footer: {
        Text("settings.translation.auto-detect-post-language-footer")
      }
    }
    .navigationTitle("settings.translation.navigation-title")
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
    .onChange(of: apiKey) {
      writeNewValue()
    }
    .onAppear(perform: updatePrefs)
  }

  private func writeNewValue() {
    writeNewValue(value: apiKey)
  }

  private func writeNewValue(value: String) {
    DeepLUserAPIHandler.write(value: value)
  }

  private func readValue() {
    if let apiKey = DeepLUserAPIHandler.readIfAllowed() {
      self.apiKey = apiKey
    } else {
      apiKey = ""
    }
  }

  private func updatePrefs() {
    DeepLUserAPIHandler.deactivateToggleIfNoKey()
  }
}

struct TranslationSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    TranslationSettingsView()
      .environmentObject(UserPreferences.shared)
  }
}
