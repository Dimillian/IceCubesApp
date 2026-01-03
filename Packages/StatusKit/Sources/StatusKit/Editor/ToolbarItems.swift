import DesignSystem
import Env
import Models
import StoreKit
import SwiftUI

extension StatusEditor {
  @MainActor
  struct ToolbarItems: ToolbarContent {
    @State private var isLanguageConfirmPresented = false
    @State private var isDismissAlertPresented: Bool = false
    @State private var isDraftsSheetDisplayed: Bool = false

    let mainStore: EditorStore
    let focusedStore: EditorStore
    let followUpStores: [EditorStore]

    @Environment(\.modelContext) private var context
    @Environment(UserPreferences.self) private var preferences
    @Environment(Theme.self) private var theme
    @Environment(ToastCenter.self) private var toastCenter

    #if targetEnvironment(macCatalyst)
      @Environment(\.dismissWindow) private var dismissWindow
    #else
      @Environment(\.dismiss) private var dismiss
    #endif

    var isSendingDisabled: Bool {
      !mainStore.canPost || mainStore.isPosting
    }

    var body: some ToolbarContent {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          isDraftsSheetDisplayed = true
        } label: {
          Image(systemName: "pencil.and.list.clipboard")
        }
        .tint(.label)
        .accessibilityLabel("accessibility.editor.button.drafts")
        .sheet(isPresented: $isDraftsSheetDisplayed) {
          if UIDevice.current.userInterfaceIdiom == .phone {
            draftsListView
          } else {
            draftsListView
          }
        }
      }

      if #available(iOS 26, *) {
        ToolbarSpacer(placement: .topBarTrailing)
        ToolbarItem(placement: .navigationBarTrailing) {
          sendButton
            .buttonStyle(.glassProminent)
            .tint(theme.tintColor)
        }
      } else {
        ToolbarItem(placement: .navigationBarTrailing) {
          sendButton
            .buttonStyle(.borderedProminent)
            .tint(theme.tintColor)
        }
      }

      ToolbarItem(placement: .navigationBarLeading) {
        Button {
          if mainStore.shouldDisplayDismissWarning {
            isDismissAlertPresented = true
          } else {
            close()
            NotificationCenter.default.post(
              name: .shareSheetClose,
              object: nil)
          }
        } label: {
          Image(systemName: "xmark")
        }
        .tint(.red)
        .keyboardShortcut(.cancelAction)
        .confirmationDialog(
          "",
          isPresented: $isDismissAlertPresented,
          actions: {
            Button("status.draft.delete", role: .destructive) {
              close()
              NotificationCenter.default.post(
                name: .shareSheetClose,
                object: nil)
            }
            Button("status.draft.save") {
              context.insert(Draft(content: mainStore.statusText.string))
              close()
              NotificationCenter.default.post(
                name: .shareSheetClose,
                object: nil)
            }
            Button("action.cancel", role: .cancel) {}
          }
        )
      }
    }

    private var sendButton: some View {
      Button {
        guard !isSendingDisabled else { return }
        mainStore.evaluateLanguages()
        if preferences.autoDetectPostLanguage,
          mainStore.languageConfirmationDialogLanguages != nil
        {
          isLanguageConfirmPresented = true
        } else {
          startPosting()
        }
      } label: {
        Image(systemName: "paperplane")
          .symbolVariant(isSendingDisabled ? .none : .fill)
          .foregroundStyle(.white)
          .bold()
      }
      .buttonBorderShape(.circle)
      .keyboardShortcut(.return, modifiers: .command)
      .confirmationDialog(
        "", isPresented: $isLanguageConfirmPresented,
        actions: {
          languageConfirmationDialog
        })
    }

    private func startPosting() {
      let toastID = toastCenter.showProgress(
        title: String(localized: "toast.posting.title"),
        systemImage: "paperplane.fill",
        tint: theme.tintColor,
        progress: 0
      )
      mainStore.postingToastID = toastID
      close()
      NotificationCenter.default.post(name: .shareSheetClose, object: nil)

      Task { @MainActor in
        let (status, errorMessage) = await postAllStatus()
        handlePostingResult(status: status, errorMessage: errorMessage, toastID: toastID)
      }
    }

    private func handlePostingResult(status: Status?, errorMessage: String?, toastID: UUID) {
      defer {
        mainStore.postingToastID = nil
      }

      if status != nil {
        let successToast = ToastCenter.Toast(
          id: toastID,
          title: String(localized: "toast.posting.success.title"),
          systemImage: "checkmark.circle.fill",
          tint: theme.tintColor,
          kind: .message
        )
        toastCenter.update(id: toastID, toast: successToast, autoDismissAfter: .seconds(3))
      } else {
        saveDraftIfNeeded()
        let savedMessage = String(localized: "toast.posting.failure.saved-to-drafts")
        let message: String
        if let errorMessage, !errorMessage.isEmpty {
          message = "\(errorMessage)\n\(savedMessage)"
        } else {
          message = savedMessage
        }
        let errorToast = ToastCenter.Toast(
          id: toastID,
          title: String(localized: "status.error.posting.title"),
          message: message,
          systemImage: "exclamationmark.triangle.fill",
          tint: .red,
          kind: .message
        )
        toastCenter.update(id: toastID, toast: errorToast, autoDismissAfter: .seconds(4))
      }
    }

    private func saveDraftIfNeeded() {
      let content = mainStore.statusText.string.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !content.isEmpty else { return }
      context.insert(Draft(content: content))
    }

    @discardableResult
    private func postStatus(with model: EditorStore, isMainPost: Bool) async -> Status? {
      let status = await model.postStatus()
      if status != nil, isMainPost {
        SoundEffectManager.shared.playSound(.tootSent)
        #if !targetEnvironment(macCatalyst)
          if !mainStore.mode.isInShareExtension, !preferences.requestedReview {
            if let scene = UIApplication.shared.connectedScenes.first(where: {
              $0.activationState == .foregroundActive
            }) as? UIWindowScene {
              AppStore.requestReview(in: scene)
            }
            preferences.requestedReview = true
          }
        #endif
      }

      return status
    }

    private func postAllStatus() async -> (Status?, String?) {
      guard var latestPost = await postStatus(with: mainStore, isMainPost: true) else {
        return (nil, mainStore.postingError)
      }
      for p in followUpStores {
        p.mode = .replyTo(status: latestPost)
        guard let post = await postStatus(with: p, isMainPost: false) else {
          return (nil, p.postingError)
        }
        latestPost = post
      }
      return (latestPost, nil)
    }

    #if targetEnvironment(macCatalyst)
      private func close() { dismissWindow() }
    #else
      private func close() { dismiss() }
    #endif

    @ViewBuilder
    private var languageConfirmationDialog: some View {
      if let (detected: detected, selected: selected) = mainStore
        .languageConfirmationDialogLanguages,
        let detectedLong = Locale.current.localizedString(forLanguageCode: detected),
        let selectedLong = Locale.current.localizedString(forLanguageCode: selected)
      {
        Button("status.editor.language-select.confirmation.detected-\(detectedLong)") {
          mainStore.selectedLanguage = detected
          startPosting()
        }
        Button("status.editor.language-select.confirmation.selected-\(selectedLong)") {
          mainStore.selectedLanguage = selected
          startPosting()
        }
        Button("action.cancel", role: .cancel) {
          mainStore.languageConfirmationDialogLanguages = nil
        }
      } else {
        EmptyView()
      }
    }

    private var draftsListView: some View {
      DraftsListView(
        selectedDraft: .init(
          get: {
            nil
          },
          set: { draft in
            if let draft {
              focusedStore.insertStatusText(text: draft.content)
            }
          }))
    }
  }
}
