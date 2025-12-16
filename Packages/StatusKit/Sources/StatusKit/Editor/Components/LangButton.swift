import DesignSystem
import Env
import Models
import SwiftUI

extension StatusEditor {
  @MainActor
  struct LangButton: View {
    @Environment(UserPreferences.self) private var preferences

    @State private var isLanguageSheetDisplayed: Bool = false

    var viewModel: ViewModel

    var body: some View {
      Button {
        isLanguageSheetDisplayed.toggle()
      } label: {
        HStack(alignment: .center) {
          Image(systemName: "text.bubble")
          if let language = viewModel.selectedLanguage {
            Text(language.uppercased())
          } else {
            Image(systemName: "globe")
          }
        }
        .font(.footnote)
      }
      .buttonStyle(.bordered)
      .onAppear {
        viewModel.setInitialLanguageSelection(
          preference: preferences.recentlyUsedLanguages.first
            ?? preferences.serverPreferences?.postLanguage)
      }
      .accessibilityLabel("accessibility.editor.button.language")
      .sheet(isPresented: $isLanguageSheetDisplayed) {
        LanguageSheetView(
          viewModel: viewModel,
          isPresented: $isLanguageSheetDisplayed
        )
      }
    }

  }
}
