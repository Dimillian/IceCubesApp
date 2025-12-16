import DesignSystem
import Env
import Models
import SwiftUI

extension StatusEditor {
  @MainActor
  struct LanguageSheetView: View {
    @Environment(Theme.self) private var theme
    @Environment(UserPreferences.self) private var preferences

    @State private var languageSearch: String = ""

    var viewModel: ViewModel
    @Binding var isPresented: Bool

    var body: some View {
      NavigationStack {
        List {
          if languageSearch.isEmpty {
            if !recentlyUsedLanguages.isEmpty {
              Section("status.editor.language-select.recently-used") {
                languageSheetSection(languages: recentlyUsedLanguages)
              }
            }
            Section {
              languageSheetSection(languages: otherLanguages)
            }
          } else {
            languageSheetSection(languages: languageSearchResult(query: languageSearch))
          }
        }
        .searchable(text: $languageSearch, placement: .navigationBarDrawer)
        .toolbar {
          CancelToolbarItem()
        }
        .navigationTitle("status.editor.language-select.navigation-title")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(theme.secondaryBackgroundColor)
      }
    }

    @ViewBuilder
    private func languageTextView(
      isoCode: String,
      nativeName: String?,
      name: String?
    ) -> some View {
      if let nativeName, let name {
        Text("\(nativeName) (\(name))")
      } else {
        Text(isoCode.uppercased())
      }
    }

    private func languageSheetSection(languages: [Language]) -> some View {
      ForEach(languages) { language in
        HStack {
          languageTextView(
            isoCode: language.isoCode,
            nativeName: language.nativeName,
            name: language.localizedName
          ).tag(language.isoCode)
          Spacer()
          if language.isoCode == viewModel.selectedLanguage {
            Image(systemName: "checkmark")
          }
        }
        .listRowBackground(theme.primaryBackgroundColor)
        .contentShape(Rectangle())
        .onTapGesture {
          viewModel.selectedLanguage = language.isoCode
          viewModel.hasExplicitlySelectedLanguage = true
          close()
        }
      }
    }

    private var recentlyUsedLanguages: [Language] {
      preferences.recentlyUsedLanguages.compactMap { isoCode in
        Language.allAvailableLanguages.first { $0.isoCode == isoCode }
      }
    }

    private var otherLanguages: [Language] {
      Language.allAvailableLanguages.filter {
        !preferences.recentlyUsedLanguages.contains($0.isoCode)
      }
    }

    private func languageSearchResult(query: String) -> [Language] {
      Language.allAvailableLanguages.filter { language in
        guard !query.isEmpty else { return true }
        return language.nativeName?.lowercased().hasPrefix(query.lowercased()) == true
          || language.localizedName?.lowercased().hasPrefix(query.lowercased()) == true
      }
    }

    private func close() {
      isPresented.toggle()
    }
  }
}
