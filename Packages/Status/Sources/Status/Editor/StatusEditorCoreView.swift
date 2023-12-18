import AppAccount
import DesignSystem
import Env
import Models
import Network
import SwiftUI

@MainActor
struct StatusEditorCoreView: View {
  @Bindable var viewModel: StatusEditorViewModel
  @Binding var followUpSEVMs: [StatusEditorViewModel]
  @Binding var editingMediaContainer: StatusEditorMediaContainer?

  @FocusState<UUID?>.Binding var isSpoilerTextFocused: UUID?
  @FocusState<StatusEditorFocusState?>.Binding var editorFocusState: StatusEditorFocusState?
  let assignedFocusState: StatusEditorFocusState
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
          StatusEditorPrivacyMenu(visibility: $viewModel.visibility, tint: isMain ? theme.tintColor : .secondary)
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
