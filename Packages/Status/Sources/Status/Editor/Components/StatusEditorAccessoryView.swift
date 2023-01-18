import DesignSystem
import Env
import Models
import PhotosUI
import SwiftUI
import NukeUI

struct StatusEditorAccessoryView: View {
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var currentInstance: CurrentInstance

  @FocusState<Bool>.Binding var isSpoilerTextFocused: Bool
  @ObservedObject var viewModel: StatusEditorViewModel

  @State private var isDraftsSheetDisplayed: Bool = false
  @State private var isLanguageSheetDisplayed: Bool = false
  @State private var isCustomEmojisSheetDisplay: Bool = false
  @State private var languageSearch: String = ""

  var body: some View {
    VStack(spacing: 0) {
      Divider()
      HStack(alignment: .center, spacing: 16) {
        PhotosPicker(selection: $viewModel.selectedMedias,
                     matching: .images) {
          Image(systemName: "photo.fill.on.rectangle.fill")
        }
        .disabled(viewModel.showPoll)

        Button {
          withAnimation {
            viewModel.showPoll.toggle()
          }
        } label: {
          Image(systemName: "chart.bar")
        }
        .disabled(viewModel.shouldDisablePollButton)

        Button {
          withAnimation {
            viewModel.spoilerOn.toggle()
          }
          isSpoilerTextFocused.toggle()
        } label: {
          Image(systemName: viewModel.spoilerOn ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
        }

        if !viewModel.mode.isInShareExtension {
          Button {
            isDraftsSheetDisplayed = true
          } label: {
            Image(systemName: "archivebox")
          }
        }
        
        if !viewModel.customEmojis.isEmpty {
          Button {
            isCustomEmojisSheetDisplay = true
          } label: {
            Image(systemName: "face.smiling.inverse")
          }
        }

        Button {
          isLanguageSheetDisplayed.toggle()
        } label: {
          if let language = viewModel.selectedLanguage {
            Text(language.uppercased())
          } else {
            Image(systemName: "globe")
          }
        }

        Spacer()

        characterCountView
      }
      .frame(height: 20)
      .padding(.horizontal, .layoutPadding)
      .padding(.vertical, 12)
      .background(.ultraThinMaterial)
    }
    .sheet(isPresented: $isDraftsSheetDisplayed) {
      draftsSheetView
    }
    .sheet(isPresented: $isLanguageSheetDisplayed) {
      languageSheetView
    }
    .sheet(isPresented: $isCustomEmojisSheetDisplay) {
      customEmojisSheet
    }
    .onAppear {
      viewModel.setInitialLanguageSelection(preference: preferences.serverPreferences?.postLanguage)
    }
  }

  @ViewBuilder
  private func languageTextView(isoCode: String, nativeName: String?, name: String?) -> some View {
    if let nativeName = nativeName, let name = name {
      Text("\(nativeName) (\(name))")
    } else {
      Text(isoCode.uppercased())
    }
  }

  private var languageSheetView: some View {
    NavigationStack {
      List {
        ForEach(availableLanguages, id: \.0) { isoCode, nativeName, name in
          HStack {
            languageTextView(isoCode: isoCode, nativeName: nativeName, name: name)
              .tag(isoCode)
            Spacer()
            if isoCode == viewModel.selectedLanguage {
              Image(systemName: "checkmark")
            }
          }
          .listRowBackground(theme.primaryBackgroundColor)
          .contentShape(Rectangle())
          .onTapGesture {
            viewModel.selectedLanguage = isoCode
            isLanguageSheetDisplayed = false
          }
        }
      }
      .searchable(text: $languageSearch)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel", action: { isLanguageSheetDisplayed = false })
        }
      }
      .navigationTitle("Select Languages")
      .navigationBarTitleDisplayMode(.inline)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
    }
  }

  private var draftsSheetView: some View {
    NavigationStack {
      List {
        ForEach(preferences.draftsPosts, id: \.self) { draft in
          Text(draft)
            .lineLimit(3)
            .listRowBackground(theme.primaryBackgroundColor)
            .onTapGesture {
              viewModel.insertStatusText(text: draft)
              isDraftsSheetDisplayed = false
            }
        }
        .onDelete { indexes in
          if let index = indexes.first {
            preferences.draftsPosts.remove(at: index)
          }
        }
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel", action: { isDraftsSheetDisplayed = false })
        }
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .navigationTitle("Drafts")
      .navigationBarTitleDisplayMode(.inline)
    }
    .presentationDetents([.medium])
  }
  
  private var customEmojisSheet: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 9) {
          ForEach(viewModel.customEmojis) { emoji in
            LazyImage(url: emoji.url) { state in
              if let image = state.image {
                image
                  .resizingMode(.aspectFit)
                  .frame(width: 40, height: 40)
              } else if state.isLoading {
                Rectangle()
                  .fill(Color.gray)
                  .frame(width: 40, height: 40)
                  .shimmering()
              }
            }
            .onTapGesture {
              viewModel.insertStatusText(text: " :\(emoji.shortcode): ")
              isCustomEmojisSheetDisplay = false
            }
          }
        }.padding(.horizontal)
      }
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
      .navigationTitle("Custom Emojis")
      .navigationBarTitleDisplayMode(.inline)
    }
    .presentationDetents([.medium])
  }

  private var characterCountView: some View {
    Text("\((currentInstance.instance?.configuration?.statuses.maxCharacters ?? 500) - viewModel.statusText.string.utf16.count)")
      .foregroundColor(.gray)
      .font(.scaledCallout)
  }

  private var availableLanguages: [(String, String?, String?)] {
    Locale.LanguageCode.isoLanguageCodes
      .filter { $0.identifier.count == 2 } // Mastodon only supports ISO 639-1 (two-letter) codes
      .map { lang in
        let nativeLocale = Locale(languageComponents: Locale.Language.Components(languageCode: lang))
        return (
          lang.identifier,
          nativeLocale.localizedString(forLanguageCode: lang.identifier),
          Locale.current.localizedString(forLanguageCode: lang.identifier)
        )
      }
      .filter { _, nativeLocale, _ in
        guard !languageSearch.isEmpty else {
          return true
        }
        return nativeLocale?.lowercased().hasPrefix(languageSearch.lowercased()) == true
      }
  }
}
