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
      translationSelector
      if preferences.preferredTranslationType == .useDeepl {
        Section("settings.translation.user-api-key") {
          deepLPicker
          SecureField("settings.translation.user-api-key", text: $apiKey)
            .textContentType(.password)
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
      backgroundAPIKey
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
      .onAppear(perform: readValue)
  }

  @ViewBuilder
  private var translationSelector: some View {
    @Bindable var preferences = preferences
    Picker("Translation Service", selection: $preferences.preferredTranslationType) {
      ForEach(allTTCases, id: \.self) { type in
        Text(type.description).tag(type)
      }
    }
    #if !os(visionOS)
    .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  var allTTCases: [TranslationType] {
    TranslationType.allCases.filter { type in
      if type != .useApple {
        return true
      }
      #if canImport(_Translation_SwiftUI)
        if #available(iOS 17.4, *) {
          return true
        } else {
          return false
        }
      #else
        return false
      #endif
    }
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
    #if !os(visionOS)
    .listRowBackground(theme.primaryBackgroundColor)
    #endif
  }

  @ViewBuilder
  private var backgroundAPIKey: some View {
    if preferences.preferredTranslationType != .useDeepl,
       !apiKey.isEmpty
    {
      Section {
        Text("The DeepL API Key is still stored!")
        if preferences.preferredTranslationType == .useServerIfPossible {
          Text("It can however still be used as a fallback for your instance's translation service.")
        }
        Button(role: .destructive) {
          withAnimation {
            writeNewValue(value: "")
            readValue()
          }
        } label: {
          Text("action.delete")
        }
      }
      #if !os(visionOS)
      .listRowBackground(theme.primaryBackgroundColor)
      #endif
    }
  }

  private func writeNewValue() {
    writeNewValue(value: apiKey)
  }

  private func writeNewValue(value: String) {
    DeepLUserAPIHandler.write(value: value)
  }

  private func readValue() {
    apiKey = DeepLUserAPIHandler.readKey()
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
