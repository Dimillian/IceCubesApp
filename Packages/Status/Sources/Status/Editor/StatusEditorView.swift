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
  @Environment(UserPreferences.self) private var preferences
  @Environment(Theme.self) private var theme
  @Environment(Client.self) private var client
  @Environment(CurrentAccount.self) private var currentAccount
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dismissWindow) private var dismissWindow
  @Environment(\.modelContext) private var context

  @State private var viewModel: StatusEditorViewModel
  @FocusState private var isSpoilerTextFocused: Bool

  @State private var isDismissAlertPresented: Bool = false
  @State private var isLanguageConfirmPresented = false

  @State private var editingContainer: StatusEditorMediaContainer?

  public init(mode: StatusEditorViewModel.Mode) {
    _viewModel = .init(initialValue: .init(mode: mode))
  }

  public var body: some View {
    NavigationStack {
      ZStack(alignment: .bottom) {
        ScrollView {
          Divider()
          spoilerTextView
          VStack(spacing: 12) {
            accountHeaderView
              .padding(.horizontal, .layoutPadding)
            TextView($viewModel.statusText,
                     getTextView: { textView in
                       viewModel.textView = textView
                     })
                     .placeholder(String(localized: "status.editor.text.placeholder"))
                     .setKeyboardType(preferences.isSocialKeyboardEnabled ? .twitter : .default)
                     .padding(.horizontal, .layoutPadding)
            StatusEditorMediaView(viewModel: viewModel,
                                  editingContainer: $editingContainer)
            if let status = viewModel.embeddedStatus {
              StatusEmbeddedView(status: status, client: client, routerPath: RouterPath())
                .padding(.horizontal, .layoutPadding)
                .disabled(true)
            } else if let status = viewModel.replyToStatus {
              Divider()
                .padding(.top, 20)
              StatusEmbeddedView(status: status, client: client, routerPath: RouterPath())
                .padding(.horizontal, .layoutPadding)
                .disabled(true)
            }
            if viewModel.showPoll {
              StatusEditorPollView(viewModel: viewModel, showPoll: $viewModel.showPoll)
                .padding(.horizontal)
            }
            Spacer()
          }
          .padding(.top, 8)
          .padding(.bottom, 40)
        }
        .accessibilitySortPriority(1) // Ensure that all elements inside the `ScrollView` occur earlier than the accessory views
        .padding(.top, 1) // hacky fix for weird SwiftUI scrollView bug when adding padding
        .padding(.bottom, 48)
        VStack(alignment: .leading, spacing: 0) {
          StatusEditorAutoCompleteView(viewModel: viewModel)
          StatusEditorAccessoryView(isSpoilerTextFocused: $isSpoilerTextFocused,
                                    viewModel: viewModel)
        }
      }
      .onDrop(of: StatusEditorUTTypeSupported.types(), delegate: viewModel)
      .onAppear {
        viewModel.client = client
        viewModel.currentAccount = currentAccount.account
        viewModel.theme = theme
        viewModel.preferences = preferences
        viewModel.prepareStatusText()
        if !client.isAuth {
          close()
          NotificationCenter.default.post(name: .shareSheetClose,
                                          object: nil)
        }

        Task {
          await viewModel.fetchCustomEmojis()
        }
      }
      .onChange(of: currentAccount.account?.id) {
        viewModel.currentAccount = currentAccount.account
      }
      .background(theme.primaryBackgroundColor)
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
      .toolbar {
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
    }
    .sheet(item: $editingContainer) { container in
      StatusEditorMediaEditView(viewModel: viewModel, container: container)
        .preferredColorScheme(theme.selectedScheme == .dark ? .dark : .light)
    }
    .interactiveDismissDisabled(viewModel.shouldDisplayDismissWarning)
    .onChange(of: appAccounts.currentClient) { _, newValue in
      if viewModel.mode.isInShareExtension {
        currentAccount.setClient(client: newValue)
        viewModel.client = newValue
      }
    }
  }

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

  private func postStatus() async {
    let status = await viewModel.postStatus()
    if status != nil {
      close()
      SoundEffectManager.shared.playSound(.tootSent)
      NotificationCenter.default.post(name: .shareSheetClose,
                                      object: nil)
      if !viewModel.mode.isInShareExtension, !preferences.requestedReview, !ProcessInfo.processInfo.isMacCatalystApp {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
          SKStoreReviewController.requestReview(in: scene)
        }
        preferences.requestedReview = true
      }
    }
  }

  @ViewBuilder
  private var spoilerTextView: some View {
    if viewModel.spoilerOn {
      VStack {
        TextField("status.editor.spoiler", text: $viewModel.spoilerText)
          .focused($isSpoilerTextFocused)
          .padding(.horizontal, .layoutPadding)
      }
      .frame(height: 35)
      .background(theme.tintColor.opacity(0.20))
      .offset(y: -8)
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
          AvatarView(account: account, config: AvatarView.FrameConfig.status)
            .environment(theme)
            .accessibilityHidden(true)
        }
        VStack(alignment: .leading, spacing: 4) {
          privacyMenu
          Text("@\(account.acct)@\(appAccounts.currentClient.server)")
            .font(.scaledFootnote)
            .foregroundColor(.gray)
        }
        Spacer()
      }
    }
  }

  private var privacyMenu: some View {
    Menu {
      Section("status.editor.visibility") {
        ForEach(Models.Visibility.allCases, id: \.self) { visibility in
          Button {
            viewModel.visibility = visibility
          } label: {
            Label(visibility.title, systemImage: visibility.iconName)
          }
        }
      }
    } label: {
      HStack {
        Label(viewModel.visibility.title, systemImage: viewModel.visibility.iconName)
          .accessibilityLabel("accessibility.editor.privacy.label")
          .accessibilityValue(viewModel.visibility.title)
          .accessibilityHint("accessibility.editor.privacy.hint")
        Image(systemName: "chevron.down")
      }
      .font(.scaledFootnote)
      .padding(4)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(theme.tintColor, lineWidth: 1)
      )
    }
  }

  private func close() {
    if ProcessInfo.processInfo.isMacCatalystApp {
      dismissWindow()
    } else {
      dismiss()
    }
  }
}
