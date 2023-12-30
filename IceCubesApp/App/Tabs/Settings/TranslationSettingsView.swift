import DesignSystem
import Env
import SwiftUI

@MainActor
struct TranslationSettingsView: View {
  @Environment(UserPreferences.self) private var preferences
  @Environment(Theme.self) private var theme

  @State private var apiKey: String = ""

  var body: some View {
    Form {
      deepLToggle
      if preferences.alwaysUseDeepl {
        Section("settings.translation.user-api-key") {
          deepLPicker
          SecureField("settings.translation.user-api-key", text: $apiKey)
            .textContentType(.password)
        }
        .onAppear {
          readValue()
        }
        #if !os(visionOS)
        .listRowBackground(theme.primaryBackgroundColor)
        #endif
        
        if apiKey.isEmpty {
          Section {
            Link(destination: URL(string: "https://www.deepl.com/pro-api")!) {
              Text("settings.translation.needed-message")
                .foregroundColor(.red)
            }
          }
          #if !os(visionOS)
          .listRowBackground(theme.primaryBackgroundColor)
          #endif
        }
      }
      autoDetectSection
    }
    .navigationTitle("settings.translation.navigation-title")
    #if !os(visionOS)
    .scrollContentBackground(.hidden)
    .background(theme.secondaryBackgroundColor)
    #endif
    .onChange(of: apiKey) {
      writeNewValue()
    }
    .onAppear(perform: updatePrefs)
  }

  @ViewBuilder
  private var deepLToggle: some View {
    @Bindable var preferences = preferences
    Toggle(isOn: $preferences.alwaysUseDeepl) {
      Text("settings.translation.always-deepl")
    }
    #if !os(visionOS)
    .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  @ViewBuilder
  private var deepLPicker: some View {
    @Bindable var preferences = preferences
    Picker("settings.translation.api-key-type", selection: $preferences.userDeeplAPIFree) {
      Text("DeepL API Free").tag(true)
      Text("DeepL API Pro").tag(false)
    }
  }

  @ViewBuilder
  private var autoDetectSection: some View {
    @Bindable var preferences = preferences
    Section {
      Toggle(isOn: $preferences.autoDetectPostLanguage) {
        Text("settings.translation.auto-detect-post-language")
      }
    } footer: {
      Text("settings.translation.auto-detect-post-language-footer")
    }
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
      .environment(UserPreferences.shared)
  }
}
