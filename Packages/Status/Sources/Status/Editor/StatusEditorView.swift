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
  @Environment(Theme.self) private var theme

  @State private var mainSEVM: StatusEditorViewModel
  @State private var followUpSEVMs: [StatusEditorViewModel] = []
  @FocusState private var isSpoilerTextFocused: UUID? // connect CoreEditor and StatusEditorAccessoryView
  @State private var editingMediaContainer: StatusEditorMediaContainer?
  @State private var scrollID: UUID?

  @FocusState private var editorFocusState: EditorFocusState?
  private var focusedSEVM: StatusEditorViewModel {
    if case let .followUp(id) = editorFocusState,
       let sevm = followUpSEVMs.first(where: { $0.id == id })
    { return sevm }

    return mainSEVM
  }

  public init(mode: StatusEditorViewModel.Mode) {
    _mainSEVM = State(initialValue: StatusEditorViewModel(mode: mode))
  }

  public var body: some View {
    @Bindable var focusedSEVM = self.focusedSEVM

    NavigationStack {
      ScrollView {
        VStackLayout(spacing: 0) {
          CoreEditor(
            viewModel: mainSEVM,
            followUpSEVMs: $followUpSEVMs,
            editingMediaContainer: $editingMediaContainer,
            isSpoilerTextFocused: $isSpoilerTextFocused,
            editorFocusState: $editorFocusState,
            assignedFocusState: .main,
            isMain: true
          )
          .id(mainSEVM.id)

          ForEach(followUpSEVMs) { sevm  in
            @Bindable var sevm: StatusEditorViewModel = sevm

            CoreEditor(
              viewModel: sevm,
              followUpSEVMs: $followUpSEVMs,
              editingMediaContainer: $editingMediaContainer,
              isSpoilerTextFocused: $isSpoilerTextFocused,
              editorFocusState: $editorFocusState,
              assignedFocusState: .followUp(index: sevm.id),
              isMain: false
            )
            .id(sevm.id)
          }
        }
        .scrollTargetLayout()
      }
      .scrollPosition(id: $scrollID, anchor: .top)
      .animation(.bouncy(duration: 0.3), value: editorFocusState)
      .animation(.bouncy(duration: 0.3), value: followUpSEVMs)
      .safeAreaInset(edge: .bottom) {
        StatusEditorAutoCompleteView(viewModel: focusedSEVM)
      }
      .safeAreaInset(edge: .bottom) {
        StatusEditorAccessoryView(isSpoilerTextFocused: $isSpoilerTextFocused, focusedSEVM: focusedSEVM, followUpSEVMs: $followUpSEVMs)
      }
      .accessibilitySortPriority(1) // Ensure that all elements inside the `ScrollView` occur earlier than the accessory views
      .navigationTitle(focusedSEVM.mode.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItems(mainSEVM: mainSEVM, followUpSEVMs: followUpSEVMs) }
      .toolbarBackground(.visible, for: .navigationBar)
      .alert(
        "status.error.posting.title",
        isPresented: $focusedSEVM.showPostingErrorAlert,
        actions: {
          Button("OK") {}
        }, message: {
          Text(mainSEVM.postingError ?? "")
        })
      .interactiveDismissDisabled(mainSEVM.shouldDisplayDismissWarning)
      .onChange(of: appAccounts.currentClient) { _, newValue in
        if mainSEVM.mode.isInShareExtension {
          currentAccount.setClient(client: newValue)
          mainSEVM.client = newValue
          for post in followUpSEVMs {
            post.client = newValue
          }
        }
      }
      .onDrop(of: StatusEditorUTTypeSupported.types(), delegate: focusedSEVM)
      .onChange(of: currentAccount.account?.id) {
        mainSEVM.currentAccount = currentAccount.account
        for p in followUpSEVMs {
          p.currentAccount = mainSEVM.currentAccount
        }
      }
      .onChange(of: mainSEVM.visibility) {
        for p in followUpSEVMs {
          p.visibility = mainSEVM.visibility
        }
      }
      .onChange(of: followUpSEVMs.count) { oldValue, newValue in
        if oldValue < newValue {
          Task {
            try? await Task.sleep(for: .seconds(0.1))
            withAnimation(.bouncy(duration: 0.5)) {
              scrollID = followUpSEVMs.last?.id
            }
          }
        }
      }
    }
    .sheet(item: $editingMediaContainer) { container in
      StatusEditorMediaEditView(viewModel: focusedSEVM, container: container)
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
  let mainSEVM: StatusEditorViewModel
  let followUpSEVMs: [StatusEditorViewModel]

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
          mainSEVM.evaluateLanguages()
          if preferences.autoDetectPostLanguage, let _ = mainSEVM.languageConfirmationDialogLanguages {
            isLanguageConfirmPresented = true
          } else {
            await postAllStatus()
          }
        }
      } label: {
        if mainSEVM.isPosting {
          ProgressView()
        } else {
          Text("status.action.post").bold()
        }
      }
      .disabled(!mainSEVM.canPost)
      .keyboardShortcut(.return, modifiers: .command)
      .confirmationDialog("", isPresented: $isLanguageConfirmPresented, actions: {
        languageConfirmationDialog
      })
    }

    ToolbarItem(placement: .navigationBarLeading) {
      Button {
        if mainSEVM.shouldDisplayDismissWarning {
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
            context.insert(Draft(content: mainSEVM.statusText.string))
            close()
            NotificationCenter.default.post(name: .shareSheetClose,
                                            object: nil)
          }
          Button("action.cancel", role: .cancel) {}
        }
      )
    }
  }

  @discardableResult
  private func postStatus(with model: StatusEditorViewModel) async -> Status? {
    let status = await model.postStatus()

    if status != nil {
      close()
      SoundEffectManager.shared.playSound(.tootSent)
      NotificationCenter.default.post(name: .shareSheetClose, object: nil)
#if !targetEnvironment(macCatalyst)
      if !mainSEVM.mode.isInShareExtension, !preferences.requestedReview {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
          SKStoreReviewController.requestReview(in: scene)
        }
        preferences.requestedReview = true
      }
#endif
    }

    return status
  }

  private func postAllStatus() async {
    guard let openingPost = await postStatus(with: mainSEVM) else { return }
    for p in followUpSEVMs {
      p.mode = .replyTo(status: openingPost)
      await postStatus(with: p)
    }
  }

#if targetEnvironment(macCatalyst)
  private func close() { dismissWindow() }
#else
  private func close() { dismiss() }
#endif

  @ViewBuilder
  private var languageConfirmationDialog: some View {
    if let (detected: detected, selected: selected) = mainSEVM.languageConfirmationDialogLanguages,
       let detectedLong = Locale.current.localizedString(forLanguageCode: detected),
       let selectedLong = Locale.current.localizedString(forLanguageCode: selected)
    {
      Button("status.editor.language-select.confirmation.detected-\(detectedLong)") {
        mainSEVM.selectedLanguage = detected
        Task { await postAllStatus() }
      }
      Button("status.editor.language-select.confirmation.selected-\(selectedLong)") {
        mainSEVM.selectedLanguage = selected
        Task { await postAllStatus() }
      }
      Button("action.cancel", role: .cancel) {
        mainSEVM.languageConfirmationDialogLanguages = nil
      }
    } else {
      EmptyView()
    }
  }
}

@MainActor
private struct CoreEditor: View {
  @Bindable var viewModel: StatusEditorViewModel
  @Binding var followUpSEVMs: [StatusEditorViewModel]
  @Binding var editingMediaContainer: StatusEditorMediaContainer?

  @FocusState<UUID?>.Binding var isSpoilerTextFocused: UUID?
  @FocusState<EditorFocusState?>.Binding var editorFocusState: EditorFocusState?
  let assignedFocusState: EditorFocusState
  let isMain: Bool

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

//  init(isSpoilerTextFocused: Bool, viewModel: StatusEditorViewModel, isFollowUPPost: Bool = false) {
//    self.isSpoilerTextFocused = isSpoilerTextFocused
//    self.viewModel = viewModel
//    self.isFollowUPPost = isFollowUPPost
//  }

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
          StatusEditorMediaView(viewModel: viewModel, editingMediaContainer: $editingMediaContainer)
          embeddedStatus
          pollView
        }
        .padding(.vertical)

        Divider()
      }
      .opacity(editorFocusState == assignedFocusState ? 1 : 0.6)
    }
    .background(theme.primaryBackgroundColor)
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

private enum EditorFocusState: Hashable { case main, followUp(index: UUID) }
