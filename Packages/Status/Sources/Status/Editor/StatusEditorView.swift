import Accounts
import AppAccount
import DesignSystem
import EmojiText
import Env
import Models
import Network
import NukeUI
import PhotosUI
import StoreKit
import SwiftUI
import UIKit

@MainActor
public struct StatusEditorView: View {
  @Environment(AppAccountsManager.self) private var appAccounts
  @Environment(CurrentAccount.self) private var currentAccount

  @State private var viewModel: StatusEditorViewModel
  @FocusState private var isSpoilerTextFocused: Bool
  @State private var editingContainer: StatusEditorMediaContainer?

  public init(mode: StatusEditorViewModel.Mode) {
    _viewModel = .init(initialValue: .init(mode: mode))
  }

  public var body: some View {
    NavigationStack {
      ScrollView {
        CoreEditor(isSpoilerTextFocused: $isSpoilerTextFocused, viewModel: viewModel)
          .padding(.vertical)
      }
      // TODO: maybe add the + button here to add follow up post
      .safeAreaInset(edge: .bottom) {
        StatusEditorAutoCompleteView(viewModel: viewModel)
      }
      .safeAreaInset(edge: .bottom) {
        StatusEditorAccessoryView(isSpoilerTextFocused: $isSpoilerTextFocused, viewModel: viewModel)
      }
      .accessibilitySortPriority(1) // Ensure that all elements inside the `ScrollView` occur earlier than the accessory views
      .onDrop(of: StatusEditorUTTypeSupported.types(), delegate: viewModel)
      .onChange(of: currentAccount.account?.id) { viewModel.currentAccount = currentAccount.account }
      .navigationTitle(viewModel.mode.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(.visible, for: .navigationBar)
      .alert("status.error.posting.title",
             isPresented: $viewModel.showPostingErrorAlert,
             actions: {
        Button("OK") {}
      }, message: {
        Text(viewModel.postingError ?? "")
      })
      .toolbar { ToolbarItems(viewModel: viewModel) }
      .sheet(item: $editingContainer) { container in
        StatusEditorMediaEditView(viewModel: viewModel, container: container)
      }
      .interactiveDismissDisabled(viewModel.shouldDisplayDismissWarning)
      .onChange(of: appAccounts.currentClient) { _, newValue in
        if viewModel.mode.isInShareExtension {
          currentAccount.setClient(client: newValue)
          viewModel.client = newValue
        }
      }
    }
  }
}

private struct PrivacyMenu: View {
  @Binding var visibility: Models.Visibility
  let tint: Color

  var body: some View {
    Menu {
      ForEach(Models.Visibility.allCases, id: \.self) { vis in
        Button { self.visibility = vis } label: {
          Label(vis.title, systemImage: vis.iconName)
        }
      }
    } label: {
      HStack {
        Label(visibility.title, systemImage: visibility.iconName)
          .accessibilityLabel("accessibility.editor.privacy.label")
          .accessibilityValue(visibility.title)
          .accessibilityHint("accessibility.editor.privacy.hint")
        Image(systemName: "chevron.down")
      }
      .font(.scaledFootnote)
      .padding(4)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(tint, lineWidth: 1)
      )
    }
  }
}

@MainActor
private struct ToolbarItems: ToolbarContent {
  @State private var isLanguageConfirmPresented = false
  @State private var isDismissAlertPresented: Bool = false
  let viewModel: StatusEditorViewModel

  @Environment(\.modelContext) private var context
  @Environment(UserPreferences.self) private var preferences
#if targetEnvironment(macCatalyst)
  @Environment(\.dismissWindow) private var dismissWindow
#else
  @Environment(\.dismiss) private var dismiss
#endif

  var body: some ToolbarContent {
    ToolbarItem(placement: .navigationBarTrailing) {
      Button {
        Task {
          viewModel.evaluateLanguages()
          if preferences.autoDetectPostLanguage, let _ = viewModel.languageConfirmationDialogLanguages {
            isLanguageConfirmPresented = true
          } else {
            await postStatus()
          }
        }
      } label: {
        if viewModel.isPosting {
          ProgressView()
        } else {
          Text("status.action.post").bold()
        }
      }
      .disabled(!viewModel.canPost)
      .keyboardShortcut(.return, modifiers: .command)
      .confirmationDialog("", isPresented: $isLanguageConfirmPresented, actions: {
        languageConfirmationDialog
      })
    }

    ToolbarItem(placement: .navigationBarLeading) {
      Button {
        if viewModel.shouldDisplayDismissWarning {
          isDismissAlertPresented = true
        } else {
          close()
          NotificationCenter.default.post(name: .shareSheetClose,
                                          object: nil)
        }
      } label: {
        Text("action.cancel")
      }
      .keyboardShortcut(.cancelAction)
      .confirmationDialog(
        "",
        isPresented: $isDismissAlertPresented,
        actions: {
          Button("status.draft.delete", role: .destructive) {
            close()
            NotificationCenter.default.post(name: .shareSheetClose,
                                            object: nil)
          }
          Button("status.draft.save") {
            context.insert(Draft(content: viewModel.statusText.string))
            close()
            NotificationCenter.default.post(name: .shareSheetClose,
                                            object: nil)
          }
          Button("action.cancel", role: .cancel) {}
        }
      )
    }
  }

  private func postStatus() async {
    let status = await viewModel.postStatus()
    if status != nil {
      close()
      SoundEffectManager.shared.playSound(.tootSent)
      NotificationCenter.default.post(name: .shareSheetClose, object: nil)
#if !targetEnvironment(macCatalyst)
      if !viewModel.mode.isInShareExtension, !preferences.requestedReview {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
          SKStoreReviewController.requestReview(in: scene)
        }
        preferences.requestedReview = true
      }
#endif
    }
  }

#if targetEnvironment(macCatalyst)
  private func close() { dismissWindow() }
#else
  private func close() { dismiss() }
#endif

  @ViewBuilder
  private var languageConfirmationDialog: some View {
    if let (detected: detected, selected: selected) = viewModel.languageConfirmationDialogLanguages,
       let detectedLong = Locale.current.localizedString(forLanguageCode: detected),
       let selectedLong = Locale.current.localizedString(forLanguageCode: selected)
    {
      Button("status.editor.language-select.confirmation.detected-\(detectedLong)") {
        viewModel.selectedLanguage = detected
        Task {
          await postStatus()
        }
      }
      Button("status.editor.language-select.confirmation.selected-\(selectedLong)") {
        viewModel.selectedLanguage = selected
        Task {
          await postStatus()
        }
      }
      Button("action.cancel", role: .cancel) {
        viewModel.languageConfirmationDialogLanguages = nil
      }
    } else {
      EmptyView()
    }
  }
}

@MainActor
private struct CoreEditor: View {
  @State private var editingContainer: StatusEditorMediaContainer?
  @FocusState<Bool>.Binding var isSpoilerTextFocused: Bool
  @Bindable var viewModel: StatusEditorViewModel

  @Environment(Theme.self) private var theme
  @Environment(UserPreferences.self) private var preferences
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(AppAccountsManager.self) private var appAccounts
  @Environment(Client.self) private var client
#if targetEnvironment(macCatalyst)
  @Environment(\.dismissWindow) private var dismissWindow
#else
  @Environment(\.dismiss) private var dismiss
#endif

  var body: some View {
    VStack {
      spoilerTextView
      accountHeaderView.padding(.horizontal, .layoutPadding)
      textInput
      StatusEditorMediaView(viewModel: viewModel, editingContainer: $editingContainer)
      embeddedStatus
      pollView
    }
    .background(theme.primaryBackgroundColor)
    .onAppear { setupViewModel() }
  }

  @ViewBuilder
  private var spoilerTextView: some View {
    if viewModel.spoilerOn {
      TextField("status.editor.spoiler", text: $viewModel.spoilerText)
        .focused($isSpoilerTextFocused)
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
          PrivacyMenu(visibility: $viewModel.visibility, tint: theme.tintColor)
          Text("@\(account.acct)@\(appAccounts.currentClient.server)")
            .font(.scaledFootnote)
            .foregroundStyle(.secondary)
        }
        Spacer()
      }
    }
  }

  private var textInput: some View {
    TextView($viewModel.statusText,
             getTextView: { textView in
      viewModel.textView = textView
    })
    .placeholder(String(localized: "status.editor.text.placeholder"))
    .setKeyboardType(preferences.isSocialKeyboardEnabled ? .twitter : .default)
    .padding(.horizontal, .layoutPadding)
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
      StatusEditorPollView(viewModel: viewModel, showPoll: $viewModel.showPoll)
        .padding(.horizontal)
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
