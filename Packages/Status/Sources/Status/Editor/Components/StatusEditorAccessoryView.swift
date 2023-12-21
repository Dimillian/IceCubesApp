import DesignSystem
import Env
#if !os(visionOS)
import GiphyUISDK
#endif
import Models
import NukeUI
import PhotosUI
import SwiftUI

@MainActor
struct StatusEditorAccessoryView: View {
  @Environment(UserPreferences.self) private var preferences
  @Environment(Theme.self) private var theme
  @Environment(CurrentInstance.self) private var currentInstance
  @Environment(\.colorScheme) private var colorScheme

  @FocusState<UUID?>.Binding var isSpoilerTextFocused: UUID?
  let focusedSEVM: StatusEditorViewModel
  @Binding var followUpSEVMs: [StatusEditorViewModel]

  @State private var isDraftsSheetDisplayed: Bool = false
  @State private var isLanguageSheetDisplayed: Bool = false
  @State private var isCustomEmojisSheetDisplay: Bool = false
  @State private var languageSearch: String = ""
  @State private var isLoadingAIRequest: Bool = false
  @State private var isPhotosPickerPresented: Bool = false
  @State private var isFileImporterPresented: Bool = false
  @State private var isCameraPickerPresented: Bool = false
  @State private var isGIFPickerPresented: Bool = false

  var body: some View {
    @Bindable var viewModel = focusedSEVM
    VStack(spacing: 0) {
      #if os(visionOS)
      HStack {
        contentView
      }
      .frame(height: 24)
      .padding(16)
      .background(.ultraThinMaterial)
      .cornerRadius(8)
      #else
      Divider()
      HStack {
        contentView
      }
      .frame(height: 20)
      .padding(.vertical, 12)
      .background(.ultraThinMaterial)
      #endif
    }
    .onAppear {
      viewModel.setInitialLanguageSelection(preference: preferences.recentlyUsedLanguages.first ?? preferences.serverPreferences?.postLanguage)
    }
  }

  @ViewBuilder
  private var contentView: some View {
    #if os(visionOS)
    HStack(spacing: 8) {
      actionsView
      characterCountView
        .padding(.leading, 16)
    }
    #else
    ScrollView(.horizontal) {
      HStack(alignment: .center, spacing: 16) {
        actionsView
      }
      .padding(.horizontal, .layoutPadding)
    }
    Spacer()
    characterCountView
      .padding(.trailing, .layoutPadding)
    #endif
  }
  
  @ViewBuilder
  private var actionsView: some View {
    @Bindable var viewModel = focusedSEVM
    Menu {
      Button {
        isPhotosPickerPresented = true
      } label: {
        Label("status.editor.photo-library", systemImage: "photo")
      }
      #if !targetEnvironment(macCatalyst)
        Button {
          isCameraPickerPresented = true
        } label: {
          Label("status.editor.camera-picker", systemImage: "camera")
        }
      #endif
      Button {
        isFileImporterPresented = true
      } label: {
        Label("status.editor.browse-file", systemImage: "folder")
      }

      #if !os(visionOS)
      Button {
        isGIFPickerPresented = true
      } label: {
        Label("GIPHY", systemImage: "party.popper")
      }
      #endif
    } label: {
      if viewModel.isMediasLoading {
        ProgressView()
      } else {
        Image(systemName: "photo.on.rectangle.angled")
      }
    }
    .photosPicker(isPresented: $isPhotosPickerPresented,
                  selection: $viewModel.mediaPickers,
                  maxSelectionCount: 4,
                  matching: .any(of: [.images, .videos]),
                  photoLibrary: .shared())
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
    .sheet(isPresented: $isGIFPickerPresented, content: {
      #if !os(visionOS)
        #if targetEnvironment(macCatalyst)
        NavigationStack {
          giphyView
          .toolbar {
            ToolbarItem(placement: .topBarLeading) {
              Button {
                isGIFPickerPresented = false
              } label: {
                Image(systemName: "xmark.circle")
              }
            }
          }
        }
        .presentationDetents([.medium, .large])
        #else
        giphyView
          .presentationDetents([.medium, .large])
        #endif
      #else
      EmptyView()
      #endif
    })
    .accessibilityLabel("accessibility.editor.button.attach-photo")
    .disabled(viewModel.showPoll)

    Button {
      // all SEVM have the same visibility value
      followUpSEVMs.append(StatusEditorViewModel(mode: .new(visibility: focusedSEVM.visibility)))
    } label: {
      Image(systemName: "arrowshape.turn.up.left.circle.fill")
    }
    .disabled(!canAddNewSEVM)

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
      isSpoilerTextFocused = viewModel.id
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
          draftsListView
            .presentationDetents([.medium])
        } else {
          draftsListView
            .frame(width: 400, height: 500)
        }
      }
    }

    if !viewModel.customEmojiContainer.isEmpty {
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

  private var canAddNewSEVM: Bool {
    guard followUpSEVMs.count < 5 else { return false }

    if followUpSEVMs.isEmpty, // there is only mainSEVM on the editor
       !focusedSEVM.statusText.string.isEmpty // focusedSEVM is also mainSEVM
    { return true }

    if let lastSEVMs = followUpSEVMs.last,
       !lastSEVMs.statusText.string.isEmpty
    { return true }

    return false
  }
  
  @ViewBuilder
  private var giphyView: some View {
    @Bindable var viewModel = focusedSEVM
    GifPickerView { url in
      GPHCache.shared.downloadAssetData(url) { data, _ in
        guard let data else { return }
        viewModel.processGIFData(data: data)
      }
      isGIFPickerPresented = false
    } onShouldDismissGifPicker: {
      isGIFPickerPresented = false
    }
  }

  private var draftsListView: some View {
    DraftsListView(selectedDraft: .init(get: {
      nil
    }, set: { draft in
      if let draft {
        focusedSEVM.insertStatusText(text: draft.content)
      }
    }))
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
            await focusedSEVM.runOpenAI(prompt: prompt.toRequestPrompt(text: focusedSEVM.statusText.string))
            isLoadingAIRequest = false
          }
        } label: {
          prompt.label
        }
      }
      if let backup = focusedSEVM.backupStatusText {
        Button {
          focusedSEVM.replaceTextWith(text: backup.string)
          focusedSEVM.backupStatusText = nil
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
        if language.isoCode == focusedSEVM.selectedLanguage {
          Image(systemName: "checkmark")
        }
      }
      .listRowBackground(theme.primaryBackgroundColor)
      .contentShape(Rectangle())
      .onTapGesture {
        focusedSEVM.selectedLanguage = language.isoCode
        focusedSEVM.hasExplicitlySelectedLanguage = true
        isLanguageSheetDisplayed = false
      }
    }
  }

  private var customEmojisSheet: some View {
    NavigationStack {
      ScrollView {
        ForEach(focusedSEVM.customEmojiContainer) { container in
          VStack(alignment: .leading) {
            Text(container.categoryName)
              .font(.scaledFootnote)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 9) {
              ForEach(container.emojis) { emoji in
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
                  focusedSEVM.insertStatusText(text: " :\(emoji.shortcode): ")
                }
              }
            }
          }
          .padding(.horizontal)
          .padding(.bottom)
        }
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
    let value = (currentInstance.instance?.configuration?.statuses.maxCharacters ?? 500) + focusedSEVM.statusTextCharacterLength

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
