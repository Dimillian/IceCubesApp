import SwiftUI
import Env

struct TranslationSettingsView: View {
  @EnvironmentObject private var preferences: UserPreferences
  @State private var apiKey: String = ""
  @State private var translateWithDeepL = false
  
    var body: some View {
      Form {
        Toggle(isOn: $translateWithDeepL) {
          Label("settings.other.always-deepl", systemImage: "captions.bubble")
        }
        .onChange(of: translateWithDeepL) { withDeepL in
          if !withDeepL {
            apiKey = ""
          }
        }
        
        if translateWithDeepL {
          Section("User API Key") {
            Picker("DeepL API Key Type", selection: $preferences.userDeeplAPIFree) {
              Text("Free").tag(true)
              Text("Pro").tag(false)
            }
            
            SecureField("API Key", text: $apiKey)
              .textContentType(.password)
          }
          
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
      .onDisappear(perform: writeNewValue)
      .onAppear(perform: readValue)
    }

  private func writeNewValue() {
    if !apiKey.isEmpty {
      KeychainHelper.save(apiKey, service: "API Token", account: "DeepL")
    } else {
      KeychainHelper.delete(service: "API Token", account: "DeepL")
    }
  }
  
  private func readValue() {
    if let apiKey = KeychainHelper.read(service: "API Token", account: "DeepL", type: String.self) {
      self.apiKey = apiKey
      translateWithDeepL = true
    } else {
      self.apiKey = ""
      translateWithDeepL = false
    }
  }
}

struct TranslationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        TranslationSettingsView()
        .environmentObject(UserPreferences.shared)
    }
}
