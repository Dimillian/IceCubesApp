import SwiftUI
import Env
import DesignSystem

struct TranslationSettingsView: View {
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var theme: Theme
  
  @State private var apiKey: String = ""
  
    var body: some View {
      Form {
        Toggle(isOn: preferences.$alwaysUseDeepl) {
          Label("settings.translation.always-deepl", systemImage: "captions.bubble")
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
          .onAppear(perform: readValue)
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
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .onChange(of: apiKey, perform: writeNewValue)
      .onDisappear(perform: writeAndUpdate)
      .onAppear(perform: updatePrefs)
    }

  private func writeNewValue() {
    writeNewValue(value: apiKey)
  }
  
  private func writeNewValue(value: String) {
    DeepLUserAPIHandler.write(value: value)
  }
  
  private func writeAndUpdate() {
    DeepLUserAPIHandler.writeAndUpdate(value: apiKey)
  }
  
  private func readValue() {
    if let apiKey = DeepLUserAPIHandler.read() {
      self.apiKey = apiKey
    } else {
      self.apiKey = ""
    }
  }
  
  private func updatePrefs() {
    DeepLUserAPIHandler.updatePreferences()
  }
}

struct TranslationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        TranslationSettingsView()
        .environmentObject(UserPreferences.shared)
    }
}
