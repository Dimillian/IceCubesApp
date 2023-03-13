import SwiftUI
import Env

struct TranslationSettingsView: View {
  @EnvironmentObject private var preferences: UserPreferences
  @State private var apiKey: String = ""
  
    var body: some View {
      Form {
        Toggle(isOn: preferences.$alwaysUseDeepl) {
          Label("settings.other.always-deepl", systemImage: "captions.bubble")
        }
        
        if preferences.alwaysUseDeepl {
          Section("User API Key") {
            Picker("DeepL API Key Type", selection: $preferences.userDeeplAPIFree) {
              Text("Free").tag(true)
              Text("Pro").tag(false)
            }
            
            SecureField("API Key", text: $apiKey)
              .textContentType(.password)
          }
          .onAppear(perform: readValue)
          
          if apiKey.isEmpty {
            Section {
              Link(destination: URL(string: "https://www.deepl.com/pro-api")!) {
                Text("A private API Key with DeepL is needed!")
                  .foregroundColor(.red)
              }
            }
          }
        }
      }
      .onSubmit(writeNewValue)
      .onDisappear(perform: writeAndUpdate)
      .onAppear(perform: updatePrefs)
    }

  private func writeNewValue() {
    DeepLUserAPIHandler.write(value: apiKey)
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
