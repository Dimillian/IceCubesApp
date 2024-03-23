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

    let mainSEVM: ViewModel
    let focusedSEVM: ViewModel
    let followUpSEVMs: [ViewModel]

    @Environment(\.modelContext) private var context
    @Environment(UserPreferences.self) private var preferences
    @Environment(Theme.self) private var theme

    #if targetEnvironment(macCatalyst)
      @Environment(\.dismissWindow) private var dismissWindow
    #else
      @Environment(\.dismiss) private var dismiss
    #endif

    var body: some ToolbarContent {
      if !mainSEVM.mode.isInShareExtension {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            isDraftsSheetDisplayed = true
          } label: {
            Image(systemName: "pencil.and.list.clipboard")
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
      }

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
          Image(systemName: "paperplane.fill")
            .bold()
        }
        .buttonStyle(.borderedProminent)
        .disabled(!mainSEVM.canPost || mainSEVM.isPosting)
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
          Image(systemName: "xmark")
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
    private func postStatus(with model: ViewModel, isMainPost: Bool) async -> Status? {
      let status = await model.postStatus()
      if status != nil, isMainPost {
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
      guard var latestPost = await postStatus(with: mainSEVM, isMainPost: true) else { return }
      for p in followUpSEVMs {
        p.mode = .replyTo(status: latestPost)
        guard let post = await postStatus(with: p, isMainPost: false) else {
          break
        }
        latestPost = post
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

    private var draftsListView: some View {
      DraftsListView(selectedDraft: .init(get: {
        nil
      }, set: { draft in
        if let draft {
          focusedSEVM.insertStatusText(text: draft.content)
        }
      }))
    }
  }
}
