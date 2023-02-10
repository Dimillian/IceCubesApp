import DesignSystem
import Env
import Models
import NukeUI
import PhotosUI
import SwiftUI

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
  @State private var isLoadingAIRequest: Bool = false

  var body: some View {
    VStack(spacing: 0) {
      Divider()
      HStack {
        ScrollView(.horizontal) {
          HStack(alignment: .center, spacing: 16) {
            PhotosPicker(selection: $viewModel.selectedMedias,
                         matching: .any(of: [.images, .videos])) {
              if viewModel.isMediasLoading {
                ProgressView()
              } else {
                Image(systemName: "photo.fill.on.rectangle.fill")
              }
            }
                         .accessibilityLabel("Attach photo")
            .disabled(viewModel.showPoll)

            Button {
              withAnimation {
                viewModel.showPoll.toggle()
              }
            } label: {
              Image(systemName: "chart.bar")
            }
            .accessibilityLabel("Poll")
            .disabled(viewModel.shouldDisablePollButton)

            Button {
              withAnimation {
                viewModel.spoilerOn.toggle()
              }
              isSpoilerTextFocused.toggle()
            } label: {
              Image(systemName: viewModel.spoilerOn ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
            }
            .accessibilityLabel("Spoiler warning")

            if !viewModel.mode.isInShareExtension {
              Button {
                isDraftsSheetDisplayed = true
              } label: {
                Image(systemName: "archivebox")
              }
              .accessibilityLabel("Drafts")
            }

            if !viewModel.customEmojis.isEmpty {
              Button {
                isCustomEmojisSheetDisplay = true
              } label: {
                Image(systemName: "face.smiling.inverse")
              }
              .accessibilityLabel("Custom Emojis")
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
            .accessibilityLabel("Language")

              if preferences.isOpenAIEnabled {
              AIMenu.disabled(!viewModel.canPost)
            }
          }
          .padding(.horizontal, .layoutPadding)
        }
        Spacer()
        characterCountView
          .padding(.trailing, .layoutPadding)
      }
      .frame(height: 20)
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

  private var AIMenu: some View {
    Menu {
      ForEach(StatusEditorAIPrompts.allCases, id: \.self) { prompt in
        Button {
          Task {
            isLoadingAIRequest = true
            await viewModel.runOpenAI(prompt: prompt.toRequestPrompt(text: viewModel.statusText.string))
            isLoadingAIRequest = false
          }
        } label: {
          prompt.label
        }
      }
      if let backup = viewModel.backupStatusText {
        Button {
          viewModel.replaceTextWith(text: backup.string)
          viewModel.backupStatusText = nil
        } label: {
          Label("status.editor.restore-previous", systemImage: "arrow.uturn.right")
        }
      }
    } label: {
      if isLoadingAIRequest {
        ProgressView()
      } else {
        Image(systemName: "faxmachine")
      }
    }
  }

  private var languageSheetView: some View {
    NavigationStack {
      List {
        if languageSearch.isEmpty {
          if !recentlyUsedLanguages.isEmpty {
            Section("Recently Used") {
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
      .searchable(text: $languageSearch)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("action.cancel", action: { isLanguageSheetDisplayed = false })
        }
      }
      .navigationTitle("status.editor.language-select.navigation-title")
      .navigationBarTitleDisplayMode(.inline)
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
    }
  }

  private func languageSheetSection(languages: [StatusEditorLanguage]) -> some View {
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
        isLanguageSheetDisplayed = false
      }
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
          Button("action.cancel", action: { isDraftsSheetDisplayed = false })
        }
      }
      .scrollContentBackground(.hidden)
      .background(theme.secondaryBackgroundColor)
      .navigationTitle("status.editor.drafts.navigation-title")
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
    Text("\((currentInstance.instance?.configuration?.statuses.maxCharacters ?? 500) + viewModel.statusTextCharacterLength)")
      .foregroundColor(.gray)
      .font(.scaledCallout)
  }

  private var recentlyUsedLanguages: [StatusEditorLanguage] {
    preferences.recentlyUsedLanguages.compactMap { isoCode in
      StatusEditorLanguage.allAvailableLanguages.first { $0.isoCode == isoCode }
    }
  }

  private var otherLanguages: [StatusEditorLanguage] {
    StatusEditorLanguage.allAvailableLanguages.filter { !preferences.recentlyUsedLanguages.contains($0.isoCode) }
  }

  private func languageSearchResult(query: String) -> [StatusEditorLanguage] {
    StatusEditorLanguage.allAvailableLanguages.filter { language in
      guard !languageSearch.isEmpty else {
        return true
      }
      return language.nativeName?.lowercased().hasPrefix(query.lowercased()) == true
        || language.localizedName?.lowercased().hasPrefix(query.lowercased()) == true
    }
  }
}
