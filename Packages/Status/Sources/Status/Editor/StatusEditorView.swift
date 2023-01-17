import Accounts
import AppAccount
import DesignSystem
import EmojiText
import Env
import Models
import Network
import NukeUI
import PhotosUI
import SwiftUI
import TextView
import UIKit

public struct StatusEditorView: View {
  @EnvironmentObject private var preferences: UserPreferences
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var client: Client
  @EnvironmentObject private var currentAccount: CurrentAccount
  @Environment(\.dismiss) private var dismiss

  @StateObject private var viewModel: StatusEditorViewModel
  @FocusState private var isSpoilerTextFocused: Bool

  @State private var isDismissAlertPresented: Bool = false
  @State private var isLoadingAIRequest: Bool = false

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
            TextView($viewModel.statusText, $viewModel.selectedRange)
              .placeholder("What's on your mind")
              .padding(.horizontal, .layoutPadding)
            StatusEditorMediaView(viewModel: viewModel)
            if let status = viewModel.embededStatus {
              StatusEmbededView(status: status)
                .padding(.horizontal, .layoutPadding)
                .disabled(true)
            } else if let status = viewModel.replyToStatus {
              Divider()
                .padding(.top, 20)
              StatusEmbededView(status: status)
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
      .onAppear {
        viewModel.client = client
        viewModel.currentAccount = currentAccount.account
        viewModel.theme = theme
        viewModel.prepareStatusText()
        if !client.isAuth {
          dismiss()
          NotificationCenter.default.post(name: NotificationsName.shareSheetClose,
                                          object: nil)
        }
      }
      .background(theme.primaryBackgroundColor)
      .navigationTitle(viewModel.mode.title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          AIMenu
            .disabled(!viewModel.canPost)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            Task {
              let status = await viewModel.postStatus()
              if status != nil {
                dismiss()
                NotificationCenter.default.post(name: NotificationsName.shareSheetClose,
                                                object: nil)
              }
            }
          } label: {
            if viewModel.isPosting {
              ProgressView()
            } else {
              Text("Post")
            }
          }
          .disabled(!viewModel.canPost)
        }
        ToolbarItem(placement: .navigationBarLeading) {
          Button {
            if !viewModel.statusText.string.isEmpty && !viewModel.mode.isInShareExtension {
              isDismissAlertPresented = true
            } else {
              dismiss()
              NotificationCenter.default.post(name: NotificationsName.shareSheetClose,
                                              object: nil)
            }
          } label: {
            Text("Cancel")
          }
          .confirmationDialog("",
                              isPresented: $isDismissAlertPresented,
                              actions: {
                                Button("Delete Draft", role: .destructive) {
                                  dismiss()
                                  NotificationCenter.default.post(name: NotificationsName.shareSheetClose,
                                                                  object: nil)
                                }
                                Button("Save Draft") {
                                  preferences.draftsPosts.insert(viewModel.statusText.string, at: 0)
                                  dismiss()
                                  NotificationCenter.default.post(name: NotificationsName.shareSheetClose,
                                                                  object: nil)
                                }
                                Button("Cancel", role: .cancel) {}
                              })
        }
      }
    }
    .interactiveDismissDisabled(!viewModel.statusText.string.isEmpty)
  }

  @ViewBuilder
  private var spoilerTextView: some View {
    if viewModel.spoilerOn {
      VStack {
        TextField("Spoiler Text", text: $viewModel.spoilerText)
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
    if let account = currentAccount.account {
      HStack {
        AppAccountsSelectorView(routeurPath: RouterPath(),
                                accountCreationEnabled: false,
                                avatarSize: .status)
        VStack(alignment: .leading, spacing: 4) {
          privacyMenu
          Text("@\(account.acct)")
            .font(.footnote)
            .foregroundColor(.gray)
        }
        Spacer()
      }
    }
  }

  private var privacyMenu: some View {
    Menu {
      Section("Post visibility") {
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
      .font(.footnote)
      .padding(4)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(theme.tintColor, lineWidth: 1)
      )
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
      if let backup = viewModel.backupStatustext {
        Button {
          viewModel.replaceTextWith(text: backup.string)
          viewModel.backupStatustext = nil
        } label: {
          Label("Restore previous text", systemImage: "arrow.uturn.right")
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
}
