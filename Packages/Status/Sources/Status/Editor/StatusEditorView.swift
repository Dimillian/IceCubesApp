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

public struct StatusEditorView: View {
  @EnvironmentObject private var appAccounts: AppAccountsManager
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentAccount: CurrentAccount
  @EnvironmentObject private var routerPath: RouterPath
  @Environment(\.dismiss) private var dismiss

  @StateObject private var viewModel: StatusEditorViewModel
  @FocusState private var isSpoilerTextFocused: Bool

  @State private var isDismissAlertPresented: Bool = false
  @State private var isLanguageConfirmPresented = false

  public init(mode: StatusEditorViewModel.Mode) {
    _viewModel = StateObject(wrappedValue: .init(mode: mode))
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
            StatusEditorMediaView(viewModel: viewModel)
            if let status = viewModel.embeddedStatus {
              StatusEmbeddedView(status: status, client: client, routerPath: routerPath)
                .padding(.horizontal, .layoutPadding)
                .disabled(true)
            } else if let status = viewModel.replyToStatus {
              Divider()
                .padding(.top, 20)
              StatusEmbeddedView(status: status, client: client, routerPath: routerPath)
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
          dismiss()
          NotificationCenter.default.post(name: NotificationsName.shareSheetClose,
                                          object: nil)
        }

        Task {
          await viewModel.fetchCustomEmojis()
        }
      }
      .onChange(of: currentAccount.account?.id, perform: { _ in
        viewModel.currentAccount = currentAccount.account
      })
      .background(theme.primaryBackgroundColor)
      .navigationTitle(viewModel.mode.title)
      .navigationBarTitleDisplayMode(.inline)
      .alert("Error while posting",
             isPresented: $viewModel.showPostingErrorAlert,
             actions: {
               Button("Ok") {}
             }, message: {
               Text(viewModel.postingError ?? "")
             })
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            Task {
              viewModel.evaluateLanguages()
              if let _ = viewModel.languageConfirmationDialogLanguages {
                isLanguageConfirmPresented = true
              } else {
                await postStatus()
              }
            }
          } label: {
            if viewModel.isPosting {
              ProgressView()
            } else {
              Text("status.action.post")
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
              dismiss()
              NotificationCenter.default.post(name: NotificationsName.shareSheetClose,
                                              object: nil)
            }
          } label: {
            Text("action.cancel")
          }
          .keyboardShortcut(.cancelAction)
          .confirmationDialog("",
                              isPresented: $isDismissAlertPresented,
                              actions: {
                                Button("status.draft.delete", role: .destructive) {
                                  dismiss()
                                  NotificationCenter.default.post(name: NotificationsName.shareSheetClose,
                                                                  object: nil)
                                }
                                Button("status.draft.save") {
                                  preferences.draftsPosts.insert(viewModel.statusText.string, at: 0)
                                  dismiss()
                                  NotificationCenter.default.post(name: NotificationsName.shareSheetClose,
                                                                  object: nil)
                                }
                                Button("action.cancel", role: .cancel) {}
                              })
        }
      }
    }
    .interactiveDismissDisabled(viewModel.shouldDisplayDismissWarning)
    .onChange(of: appAccounts.currentClient) { newClient in
      if viewModel.mode.isInShareExtension {
        currentAccount.setClient(client: newClient)
        viewModel.client = newClient
      }
    }
  }

  @ViewBuilder
  private var languageConfirmationDialog: some View {
    if let dialogVals = viewModel.languageConfirmationDialogLanguages,
       let detected = dialogVals["detected"],
       let detectedLong = Locale.current.localizedString(forLanguageCode: detected),
       let selected = dialogVals["selected"],
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
      dismiss()
      NotificationCenter.default.post(name: NotificationsName.shareSheetClose,
                                      object: nil)
      if !viewModel.mode.isInShareExtension && !preferences.requestedReview {
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
                                  avatarSize: .status)
        } else {
          AvatarView(url: account.avatar, size: .status)
            .environmentObject(theme)
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
}
