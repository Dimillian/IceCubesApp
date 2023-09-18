import DesignSystem
import Env
import Models
import NukeUI
import PhotosUI
import SwiftUI

struct StatusEditorAccessoryView: View {
  @EnvironmentObject private var preferences: UserPreferences
  @Environment(Theme.self) private var theme
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(\.colorScheme) private var colorScheme

  @FocusState<Bool>.Binding var isSpoilerTextFocused: Bool
  var viewModel: StatusEditorViewModel

  @State private var isDraftsSheetDisplayed: Bool = false
  @State private var isLanguageSheetDisplayed: Bool = false
  @State private var isCustomEmojisSheetDisplay: Bool = false
  @State private var languageSearch: String = ""
  @State private var isLoadingAIRequest: Bool = false
  @State private var isPhotosPickerPresented: Bool = false
  @State private var isFileImporterPresented: Bool = false
  @State private var isCameraPickerPresented: Bool = false

  var body: some View {
    @Bindable var viewModel = viewModel
    VStack(spacing: 0) {
      Divider()
      HStack {
        ScrollView(.horizontal) {
          HStack(alignment: .center, spacing: 16) {
            Menu {
              Button {
                isPhotosPickerPresented = true
              } label: {
                Label("status.editor.photo-library", systemImage: "photo")
              }
              if !ProcessInfo.processInfo.isiOSAppOnMac {
                Button {
                  isCameraPickerPresented = true
                } label: {
                  Label("status.editor.camera-picker", systemImage: "camera")
                }
              }
              Button {
                isFileImporterPresented = true
              } label: {
                Label("status.editor.browse-file", systemImage: "folder")
              }
            } label: {
              if viewModel.isMediasLoading {
                ProgressView()
              } else {
                Image(systemName: "photo.on.rectangle.angled")
              }
            }
            .photosPicker(isPresented: $isPhotosPickerPresented,
                          selection: $viewModel.selectedMedias,
                          maxSelectionCount: 4,
                          matching: .any(of: [.images, .videos]))
            .fileImporter(isPresented: $isFileImporterPresented,
                          allowedContentTypes: [.image, .video],
                          allowsMultipleSelection: true)
            { result in
              if let urls = try? result.get() {
                viewModel.processURLs(urls: urls)
              }
            }
            .fullScreenCover(isPresented: $isCameraPickerPresented, content: {
              StatusEditorCameraPickerView(selectedImage: .init(get: {
                nil
              }, set: { image in
                if let image {
                  viewModel.processCameraPhoto(image: image)
                }
              }))
              .background(.black)
            })
            .accessibilityLabel("accessibility.editor.button.attach-photo")
            .disabled(viewModel.showPoll)

            Button {
              withAnimation {
                viewModel.showPoll.toggle()
                viewModel.resetPollDefaults()
              }
            } label: {
              Image(systemName: "chart.bar")
            }
            .accessibilityLabel("accessibility.editor.button.poll")
            .disabled(viewModel.shouldDisablePollButton)

            Button {
              withAnimation {
                viewModel.spoilerOn.toggle()
              }
              isSpoilerTextFocused.toggle()
            } label: {
              Image(systemName: viewModel.spoilerOn ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
            }
            .accessibilityLabel("accessibility.editor.button.spoiler")

            if !viewModel.mode.isInShareExtension {
              Button {
                isDraftsSheetDisplayed = true
              } label: {
                Image(systemName: "archivebox")
              }
              .accessibilityLabel("accessibility.editor.button.drafts")
              .popover(isPresented: $isDraftsSheetDisplayed) {
                if UIDevice.current.userInterfaceIdiom == .phone {
                  draftsSheetView
                } else {
                  draftsSheetView
                    .frame(width: 400, height: 500)
                }
              }
            }

            if !viewModel.customEmojis.isEmpty {
              Button {
                isCustomEmojisSheetDisplay = true
              } label: {
                // This is a workaround for an apparent bug in the `face.smiling` SF Symbol.
                // See https://github.com/Dimillian/IceCubesApp/issues/1193
                let customEmojiSheetIconName = colorScheme == .light ? "face.smiling" : "face.smiling.inverse"
                Image(systemName: customEmojiSheetIconName)
              }
              .accessibilityLabel("accessibility.editor.button.custom-emojis")
              .popover(isPresented: $isCustomEmojisSheetDisplay) {
                if UIDevice.current.userInterfaceIdiom == .phone {
                  customEmojisSheet
                } else {
                  customEmojisSheet
                    .frame(width: 400, height: 500)
                }
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
            .accessibilityLabel("accessibility.editor.button.language")
            .popover(isPresented: $isLanguageSheetDisplayed) {
              if UIDevice.current.userInterfaceIdiom == .phone {
                languageSheetView
              } else {
                languageSheetView
                  .frame(width: 400, height: 500)
              }
            }

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
    .onAppear {
      viewModel.setInitialLanguageSelection(preference: preferences.recentlyUsedLanguages.first ?? preferences.serverPreferences?.postLanguage)
    }
  }

  @ViewBuilder
  private func languageTextView(isoCode: String, nativeName: String?, name: String?) -> some View {
    if let nativeName, let name {
      Text("\(nativeName) (\(name))")
    } else {
      Text(isoCode.uppercased())
    }
  }

  private var AIMenu: some View {
    Menu {
      ForEach(StatusEditorAIPrompt.allCases, id: \.self) { prompt in
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
          .accessibilityLabel("accessibility.editor.button.ai-prompt")
      }
    }
  }

  private var languageSheetView: some View {
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
        isLanguageSheetDisplayed = false
      }
    }
  }

  private var draftsSheetView: some View {
    NavigationStack {
      List {
        ForEach(preferences.draftsPosts, id: \.self) { draft in
          Button {
            viewModel.insertStatusText(text: draft)
            isDraftsSheetDisplayed = false
          } label: {
            Text(draft)
              .lineLimit(3)
              .foregroundStyle(theme.labelColor)
          }.listRowBackground(theme.primaryBackgroundColor)
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
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .frame(width: 40, height: 40)
                  .accessibilityLabel(emoji.shortcode.replacingOccurrences(of: "_", with: " "))
                  .accessibilityAddTraits(.isButton)
              } else if state.isLoading {
                Rectangle()
                  .fill(Color.gray)
                  .frame(width: 40, height: 40)
                  .accessibility(hidden: true)
                  .shimmering()
              }
            }
            .onTapGesture {
              viewModel.insertStatusText(text: " :\(emoji.shortcode): ")
            }
          }
        }.padding(.horizontal)
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("action.cancel", action: { isCustomEmojisSheetDisplay = false })
        }
      }
      .scrollContentBackground(.hidden)
      .background(theme.primaryBackgroundColor)
      .navigationTitle("status.editor.emojis.navigation-title")
      .navigationBarTitleDisplayMode(.inline)
    }
    .presentationDetents([.medium])
  }

  @ViewBuilder
  private var characterCountView: some View {
    let value = (currentInstance.instance?.configuration?.statuses.maxCharacters ?? 500) + viewModel.statusTextCharacterLength

    Text("\(value)")
      .foregroundColor(value < 0 ? .red : .secondary)
      .font(.scaledCallout)
      .accessibilityLabel("accessibility.editor.button.characters-remaining")
      .accessibilityValue("\(value)")
      .accessibilityRemoveTraits(.isStaticText)
      .accessibilityAddTraits(.updatesFrequently)
      .accessibilityRespondsToUserInteraction(false)
  }

  private var recentlyUsedLanguages: [Language] {
    preferences.recentlyUsedLanguages.compactMap { isoCode in
      Language.allAvailableLanguages.first { $0.isoCode == isoCode }
    }
  }

  private var otherLanguages: [Language] {
    Language.allAvailableLanguages.filter { !preferences.recentlyUsedLanguages.contains($0.isoCode) }
  }

  private func languageSearchResult(query: String) -> [Language] {
    Language.allAvailableLanguages.filter { language in
      guard !languageSearch.isEmpty else {
        return true
      }
      return language.nativeName?.lowercased().hasPrefix(query.lowercased()) == true
        || language.localizedName?.lowercased().hasPrefix(query.lowercased()) == true
    }
  }
}
