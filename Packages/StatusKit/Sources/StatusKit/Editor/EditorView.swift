import AppAccount
import DesignSystem
import Env
import Models
import Network
import SwiftUI

extension StatusEditor {
  @MainActor
  struct EditorView: View {
    @Environment(Theme.self) private var theme
    @Environment(UserPreferences.self) private var preferences
    @Environment(CurrentAccount.self) private var currentAccount
    @Environment(CurrentInstance.self) private var currentInstance
    @Environment(AppAccountsManager.self) private var appAccounts
    @Environment(Client.self) private var client
    #if targetEnvironment(macCatalyst)
      @Environment(\.dismissWindow) private var dismissWindow
    #else
      @Environment(\.dismiss) private var dismiss
    #endif
    
    @Bindable var viewModel: ViewModel
    @Binding var followUpSEVMs: [ViewModel]
    @Binding var editingMediaContainer: MediaContainer?
    
    @State private var isLanguageSheetDisplayed: Bool = false
    @State private var languageSearch: String = ""

    @FocusState<UUID?>.Binding var isSpoilerTextFocused: UUID?
    @FocusState<EditorFocusState?>.Binding var editorFocusState: EditorFocusState?
    let assignedFocusState: EditorFocusState
    let isMain: Bool

    var body: some View {
      HStack(spacing: 0) {
        if !isMain {
          Rectangle()
            .fill(theme.tintColor)
            .frame(width: 2)
            .accessibilityHidden(true)
            .padding(.leading, .layoutPadding)
        }

        VStack(spacing: 0) {
          spoilerTextView
          VStack(spacing: 0) {
            accountHeaderView
            textInput
            characterCountAndLangView
            MediaView(viewModel: viewModel, editingMediaContainer: $editingMediaContainer)
            embeddedStatus
            pollView
          }
          .padding(.vertical)

          Divider()
        }
        .opacity(editorFocusState == assignedFocusState ? 1 : 0.6)
      }
      #if !os(visionOS)
      .background(theme.primaryBackgroundColor)
      #endif
      .focused($editorFocusState, equals: assignedFocusState)
      .onAppear { setupViewModel() }
    }

    @ViewBuilder
    private var spoilerTextView: some View {
      if viewModel.spoilerOn {
        TextField("status.editor.spoiler", text: $viewModel.spoilerText)
          .focused($isSpoilerTextFocused, equals: viewModel.id)
          .padding(.horizontal, .layoutPadding)
          .padding(.vertical)
          .background(theme.tintColor.opacity(0.20))
      }
    }

    @ViewBuilder
    private var accountHeaderView: some View {
      if let account = currentAccount.account, !viewModel.mode.isEditing {
        HStack {
          if viewModel.mode.isInShareExtension {
            AppAccountsSelectorView(routerPath: RouterPath(),
                                    accountCreationEnabled: false,
                                    avatarConfig: .status)
          } else {
            AvatarView(account.avatar, config: AvatarView.FrameConfig.status)
              .environment(theme)
              .accessibilityHidden(true)
          }

          VStack(alignment: .leading, spacing: 4) {
            PrivacyMenu(visibility: $viewModel.visibility, tint: isMain ? theme.tintColor : .secondary)
              .disabled(!isMain)

            Text("@\(account.acct)@\(appAccounts.currentClient.server)")
              .font(.scaledFootnote)
              .foregroundStyle(.secondary)
          }

          Spacer()

          if case let .followUp(id) = assignedFocusState {
            Button {
              followUpSEVMs.removeAll { $0.id == id }
            } label: {
              HStack {
                Image(systemName: "minus.circle.fill").foregroundStyle(.red)
              }
            }
          }
        }
        .padding(.horizontal, .layoutPadding)
      }
    }

    private var textInput: some View {
      TextView(
        $viewModel.statusText,
        getTextView: { textView in viewModel.textView = textView }
      )
      .placeholder(String(localized: isMain ? "status.editor.text.placeholder" : "status.editor.follow-up.text.placeholder"))
      .setKeyboardType(preferences.isSocialKeyboardEnabled ? .twitter : .default)
      .padding(.horizontal, .layoutPadding)
      .padding(.vertical)
    }

    @ViewBuilder
    private var embeddedStatus: some View {
      if viewModel.replyToStatus != nil { Divider().padding(.top, 20) }

      if let status = viewModel.embeddedStatus ?? viewModel.replyToStatus {
        StatusEmbeddedView(status: status, client: client, routerPath: RouterPath())
          .padding(.horizontal, .layoutPadding)
          .disabled(true)
      }
    }

    @ViewBuilder
    private var pollView: some View {
      if viewModel.showPoll {
        PollView(viewModel: viewModel, showPoll: $viewModel.showPoll)
          .padding(.horizontal)
      }
    }
    
    
    @ViewBuilder
    private var characterCountAndLangView: some View {
      let value = (currentInstance.instance?.configuration?.statuses.maxCharacters ?? 500) + viewModel.statusTextCharacterLength
      HStack(alignment: .center) {
        Text("\(value)")
          .foregroundColor(value < 0 ? .red : .secondary)
          .font(.scaledCallout)
          .accessibilityLabel("accessibility.editor.button.characters-remaining")
          .accessibilityValue("\(value)")
          .accessibilityRemoveTraits(.isStaticText)
          .accessibilityAddTraits(.updatesFrequently)
          .accessibilityRespondsToUserInteraction(false)
          .padding(.leading, .layoutPadding)
        
        Button {
          isLanguageSheetDisplayed.toggle()
        } label: {
          HStack(alignment: .center) {
            if let language = viewModel.selectedLanguage {
              Image(systemName: "text.bubble")
              Text(language.uppercased())
            } else {
              Image(systemName: "globe")
            }
          }
          .font(.footnote)
        }
        .buttonStyle(.bordered)
        .onAppear {
          viewModel.setInitialLanguageSelection(preference: preferences.recentlyUsedLanguages.first ?? preferences.serverPreferences?.postLanguage)
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
        
        Spacer()
      }
      .padding(.bottom, 8)
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
    
    
    @ViewBuilder
    private func languageTextView(isoCode: String, nativeName: String?, name: String?) -> some View {
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
          isLanguageSheetDisplayed = false
        }
      }
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

    private func setupViewModel() {
      viewModel.client = client
      viewModel.currentAccount = currentAccount.account
      viewModel.theme = theme
      viewModel.preferences = preferences
      viewModel.prepareStatusText()
      if !client.isAuth {
        #if targetEnvironment(macCatalyst)
          dismissWindow()
        #else
          dismiss()
        #endif
        NotificationCenter.default.post(name: .shareSheetClose, object: nil)
      }

      Task { await viewModel.fetchCustomEmojis() }
    }
  }

}
