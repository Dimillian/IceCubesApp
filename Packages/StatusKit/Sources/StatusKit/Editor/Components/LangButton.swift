import DesignSystem
import Env
import Models
import SwiftUI

extension StatusEditor {
  @MainActor
  struct LangButton: View {
    @Environment(UserPreferences.self) private var preferences

    @State private var isLanguageSheetDisplayed: Bool = false

    var store: EditorStore

    var body: some View {
      Button {
        isLanguageSheetDisplayed.toggle()
      } label: {
        HStack(alignment: .center) {
          Image(systemName: "text.bubble")
          if let language = store.selectedLanguage {
            Text(language.uppercased())
          } else {
            Image(systemName: "globe")
          }
        }
        .font(.footnote)
      }
      .buttonStyle(.bordered)
      .onAppear {
        store.setInitialLanguageSelection(
          preference: preferences.recentlyUsedLanguages.first
            ?? preferences.serverPreferences?.postLanguage)
      }
      .accessibilityLabel("accessibility.editor.button.language")
      .sheet(isPresented: $isLanguageSheetDisplayed) {
        LanguageSheetView(
          store: store,
          isPresented: $isLanguageSheetDisplayed
        )
      }
    }

  }
}
